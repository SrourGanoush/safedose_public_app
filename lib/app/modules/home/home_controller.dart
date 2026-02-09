import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../dashboard/dashboard_controller.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/local_history_service.dart';
import '../../data/services/tts_service.dart';
import '../../data/models/medicine.dart';
import '../../data/models/company_profile.dart';
import '../../data/models/user_model.dart';
import '../../data/utils/gs1_parser.dart';
import '../../../main.dart'; // To access global cameras list

enum VerificationStep { scanCode, capturePackage, visualAnalysis, result }

class HomeController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final GeminiService _geminiService = Get.find<GeminiService>();
  final AuthService _authService = Get.find<AuthService>();
  final LocalHistoryService _historyService = Get.find<LocalHistoryService>();
  final TtsService _ttsService = Get.find<TtsService>();
  final DashboardController _dashboardController =
      Get.find<DashboardController>();

  // Use the shared scanner from DashboardController
  MobileScannerController get scannerController =>
      _dashboardController.sharedScanner!;

  CameraController? cameraController;
  final isCameraInitialized = false.obs;

  var currentStep = VerificationStep.scanCode.obs;
  var isScanning = true.obs;
  var scanResult = ''.obs;
  var capturedImage = Rxn<Uint8List>();
  var verificationStatus = 'Ready to Scan'.obs;
  var geminiAnalysis = ''.obs;
  var foundMedicine = Rxn<Medicine>();
  var distributorProfile = Rxn<CompanyProfile>();
  var isUpdatingStatus = false.obs;
  var latestImage = Rxn<Uint8List>();

  // Key to force MobileScanner rebuild
  var scannerKey = 0.obs;

  // Use variables for new features
  var expiryStatus = 'Valid'.obs; // Valid, Expiring Soon, Expired
  var medicineExplanation = ''.obs;
  var isExplaining = false.obs;

  // Current user role for UI decisions
  UserRole? get currentUserRole => _authService.currentAppUser.value?.role;

  // --- Camera Management ---

  Future<void> initCamera() async {
    // Stop scanner and wait for hardware to release
    await scannerController.stop();
    await Future.delayed(const Duration(milliseconds: 300));

    final backCamera = cameras.firstWhereOrNull(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    cameraController = CameraController(
      backCamera ?? cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await cameraController!.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      Get.snackbar('Camera Error', 'Failed to initialize camera: $e');
    }
  }

  Future<void> disposeCamera() async {
    // Guard against disposing while a capture is in progress
    // This prevents "BufferQueue has been abandoned" crashes if the user
    // tries to switch tabs or reset while the camera is writing the file.
    int retries = 0;
    while (isCapturing.value && retries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (cameraController != null) {
      // Ensure we don't dispose if it's already null/disposed in another race
      try {
        await cameraController!.dispose();
      } catch (e) {
        print('Error disposing camera: $e');
      }
      cameraController = null;
      isCameraInitialized.value = false;
    }
  }

  // --- Scan Logic ---

  void onScan(BarcodeCapture capture) async {
    if (capture.image != null) {
      latestImage.value = capture.image;
    }

    if (!isScanning.value || currentStep.value != VerificationStep.scanCode) {
      return;
    }

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code != scanResult.value) {
        scanResult.value = code;
      }
    }
  }

  Future<void> performScan() async {
    final code = scanResult.value;
    if (code.isEmpty) {
      Get.snackbar('No Code Detected', 'Please point the camera at a barcode');
      return;
    }

    await scannerController.stop();
    await Future.delayed(const Duration(milliseconds: 200));

    currentStep.value = VerificationStep.capturePackage;
    verificationStatus.value = 'Code detected. Loading camera...';

    await initCamera();
    verificationStatus.value =
        'Please point at the package and tap "Verify Appearance".';
  }

  var isCapturing = false.obs;

  Future<void> capturePackagePhoto() async {
    if (currentStep.value != VerificationStep.capturePackage) return;
    if (isCapturing.value) return; // Prevent double taps

    try {
      if (cameraController == null || !isCameraInitialized.value) {
        Get.snackbar('Error', 'Camera not ready. Please wait.');
        return;
      }

      isCapturing.value = true;
      final XFile photo = await cameraController!.takePicture();

      // CRITICAL: Pause preview immediately to stop frame production
      // This helps prevent "BufferQueue has been abandoned" if the surface is destroyed quickly
      try {
        await cameraController!.pausePreview();
      } catch (e) {
        print("Error pausing preview: $e");
      }

      final bytes = await photo.readAsBytes();

      // CRITICAL: Mark capturing as done BEFORE calling disposeCamera
      // otherwise disposeCamera will wait for this flag locally and deadlock/timeout
      isCapturing.value = false;

      capturedImage.value = bytes;
      isScanning.value = false;

      // Small delay before disposal to let hardware catch up
      await Future.delayed(const Duration(milliseconds: 100));
      await disposeCamera();
      currentStep.value = VerificationStep.result;

      await verifyCode(scanResult.value, bytes);
    } catch (e) {
      print('Camera capture error: $e');
      Get.snackbar('Error', 'Camera capture error: $e');
    } finally {
      // Ensure flag is reset in case of error (if not already reset)
      isCapturing.value = false;
    }
  }

  // --- Business Logic ---

  Future<void> verifyCode(String code, [Uint8List? image]) async {
    verificationStatus.value = 'Analyzing...';
    distributorProfile.value = null;
    geminiAnalysis.value = '';
    medicineExplanation.value = ''; // Reset explanation
    foundMedicine.value = null; // Reset

    final gs1Data = GS1Parser.parse(code);
    String gtin = gs1Data['gtin'] ?? '';
    String serial = gs1Data['serial'] ?? '';
    if (gtin.isEmpty && !code.contains(GS1Parser.GROUP_SEPARATOR)) gtin = code;

    try {
      Medicine? medicine = await _firestoreService.getMedicine(gtin, serial);
      foundMedicine.value = medicine;

      if (medicine != null) {
        verificationStatus.value = 'Step 1: Found in Ledger';
        checkExpiry(medicine.expiryDate);

        if (medicine.distributorId.isNotEmpty) {
          final distributorUser = await _firestoreService.getUser(
            medicine.distributorId,
          );
          if (distributorUser?.companyId != null) {
            final profile = await _firestoreService.getDistributorProfile(
              distributorUser!.companyId!,
            );
            distributorProfile.value = profile;
          }
        }
      } else {
        verificationStatus.value = 'Step 1: Not Found in Ledger';
        expiryStatus.value = 'Unknown';
      }

      verificationStatus.value = 'Step 2: AI Describing Medicine...';
      final analysis = await _geminiService.analyzeMedicine(
        code,
        medicine,
        image,
      );
      geminiAnalysis.value = analysis;

      await _historyService.addRecord(medicine, verificationVerdict, analysis);

      // TTS Announcement
      _announceResult();
    } catch (e) {
      verificationStatus.value = 'Error: $e';
    }
  }

  void checkExpiry(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;

    if (expiryDate.isBefore(now)) {
      expiryStatus.value = 'Expired';
    } else if (difference <= 30) {
      expiryStatus.value = 'Expiring Soon';
    } else {
      expiryStatus.value = 'Valid';
    }
  }

  Future<void> explainMedicine() async {
    if (foundMedicine.value == null && geminiAnalysis.value.isEmpty) return;

    isExplaining.value = true;
    String name = foundMedicine.value?.manufacturerName ?? 'This medicine';
    String context = geminiAnalysis.value;

    final explanation = await _geminiService.explainMedicine(name, context);
    medicineExplanation.value = explanation;
    isExplaining.value = false;

    // Read out the explanation
    _ttsService.speak(explanation);
  }

  Future<void> translateLabel(String targetLang) async {
    if (geminiAnalysis.value.isEmpty) return;

    isExplaining.value = true;
    // We use the full analysis or even the raw image if we could pass it again,
    // but for now let's translate the analysis/extracted text as a proxy or
    // real implementation would re-send image for specific text translation.
    // Simplifying: Translate the Visual Description.

    final text = visualDescription;
    final translation = await _geminiService.translateLabel(text, targetLang);

    medicineExplanation.value = "Translation ($targetLang):\n$translation";
    isExplaining.value = false;
    _ttsService.speak(translation);
  }

  Future<void> reportToAuthorities() async {
    final user = _authService.currentUser.value;
    if (user == null) {
      Get.snackbar('Error', 'You must be logged in to report.');
      return;
    }

    // 1. Get Location (Optional but recommended)
    Map<String, dynamic>? locationData;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        };
      }
    } catch (e) {
      print("Location error: $e");
      // Continue without location if it fails
    }

    try {
      String reason = 'Suspicious';
      if (isVisualMismatch) reason = 'Counterfeit / Visual Mismatch';
      if (expiryStatus.value == 'Expired') reason = 'Expired Medicine Sold';
      if (foundMedicine.value == null) reason = 'Unregistered Medicine';

      await _firestoreService.submitReport(
        gtin: foundMedicine.value?.gtin,
        serial: foundMedicine.value?.serialNumber,
        reason: reason,
        description: geminiAnalysis.value,
        userId: user.uid,
        scanData: scanResult.value,
        location: locationData,
      );

      Get.snackbar(
        'Report Submitted',
        'Thank you. Authorities have been notified with your location.',
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      _ttsService.speak("Report submitted with location. Thank you.");
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit report: $e');
    }
  }

  void _announceResult() {
    String message = '';
    if (isVisualMismatch) {
      message =
          "Warning. Potential counterfeit detected. Please check your screen.";
    } else if (expiryStatus.value == 'Expired') {
      message = "Warning. This medicine is Expired. Do not use.";
    } else if (foundMedicine.value != null) {
      message = "Medicine Verified. Status is ${expiryStatus.value}.";
    } else {
      message = "Medicine not found in ledger. Please be careful.";
    }
    _ttsService.speak(message);
  }

  // Expose toggle for manual TTS
  void speakText(String text) {
    _ttsService.speak(text);
  }

  Future<void> updateMedicineStatus(String newStatus) async {
    final medicine = foundMedicine.value;
    final userId = _authService.currentUser.value?.uid;

    if (medicine == null || userId == null) {
      Get.snackbar('Error', 'No medicine scanned or user not logged in');
      return;
    }

    try {
      isUpdatingStatus.value = true;
      await _firestoreService.updateMedicineStatus(
        medicine.gtin,
        medicine.serialNumber,
        newStatus,
        userId,
      );

      final updatedMedicine = await _firestoreService.getMedicine(
        medicine.gtin,
        medicine.serialNumber,
      );
      foundMedicine.value = updatedMedicine;
      verificationStatus.value = 'Status updated to: $newStatus';
      Get.snackbar('Success', 'Medicine status updated to $newStatus');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e');
    } finally {
      isUpdatingStatus.value = false;
    }
  }

  Future<void> toggleScan() async {
    if (isScanning.value) {
      verificationStatus.value = 'Scan Paused';
      isScanning.value = false;
      await scannerController.stop();
    } else {
      if (currentStep.value == VerificationStep.result ||
          currentStep.value == VerificationStep.capturePackage) {
        await resetScan();
      } else {
        isScanning.value = true;
        await scannerController.start();
      }
    }
  }

  Future<void> resetScan() async {
    await disposeCamera();
    _ttsService.stop(); // Stop speaking

    // UI Cleanup
    scanResult.value = '';
    capturedImage.value = null;
    geminiAnalysis.value = '';
    medicineExplanation.value = '';
    foundMedicine.value = null;
    distributorProfile.value = null;
    verificationStatus.value = 'Ready to Scan';
    currentStep.value = VerificationStep.scanCode;

    // Hardware cooldown delay to prevent white screen
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      isScanning.value = true;
      refreshScannerKey(); // Force widget rebuild
      await scannerController.start();
    } catch (e) {
      print("Scanner restart failed: $e");
      await Future.delayed(const Duration(milliseconds: 200));
      await scannerController.start();
    }
  }

  void refreshScannerKey() {
    scannerKey.value++;
  }

  // Helpers
  String get visualDescription {
    if (geminiAnalysis.value.contains('VISUAL DESCRIPTION:')) {
      final parts = geminiAnalysis.value.split('VERDICT:');
      return parts[0].replaceAll('VISUAL DESCRIPTION:', '').trim();
    }
    return geminiAnalysis.value;
  }

  String get verificationVerdict {
    if (geminiAnalysis.value.contains('VERDICT:')) {
      final parts = geminiAnalysis.value.split('VERDICT:');
      return parts.length > 1 ? parts[1].trim() : 'Refer to description';
    }
    return 'Analysis pending...';
  }

  bool get isVisualMismatch =>
      geminiAnalysis.value.toUpperCase().contains('VISUAL MISMATCH');

  @override
  void onClose() {
    disposeCamera();
    _ttsService.stop();
    super.onClose();
  }
}
