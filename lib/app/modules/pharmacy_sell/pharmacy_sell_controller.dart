import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../dashboard/dashboard_controller.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/medicine.dart';
import '../../data/utils/gs1_parser.dart';

class PharmacySellController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();
  final DashboardController _dashboardController =
      Get.find<DashboardController>();

  // Use the shared scanner from DashboardController
  MobileScannerController get scannerController {
    if (_dashboardController.sharedScanner == null) {
      return MobileScannerController();
    }
    return _dashboardController.sharedScanner!;
  }

  // States
  var currentStep =
      0.obs; // 0 = camera preview, 1 = loading lookp, 2 = sell screen
  var lastDetectedCode = ''.obs;
  var statusMessage = 'Scan medicine to mark as sold'.obs;
  var foundMedicine = Rxn<Medicine>();
  var isLoading = false.obs;
  var isUpdating = false.obs;
  var saleCompleted = false.obs;

  // Called continuously by MobileScanner - just store the latest code
  void onScan(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        lastDetectedCode.value = code;
      }
    }
  }

  // Called when user presses SCAN button
  Future<void> performScan() async {
    final code = lastDetectedCode.value;

    if (code.isEmpty) {
      Get.snackbar('No Code Detected', 'Please point the camera at a barcode');
      return;
    }

    // Move to loading step (keep scanner active in background)
    currentStep.value = 1;
    isLoading.value = true;
    statusMessage.value = 'Looking up medicine...';
    foundMedicine.value = null;
    saleCompleted.value = false;

    await lookupMedicine(code);
  }

  Future<void> lookupMedicine(String code) async {
    try {
      final gs1Data = GS1Parser.parse(code);
      String gtin = gs1Data['gtin'] ?? '';
      String serial = gs1Data['serial'] ?? '';

      if (gtin.isEmpty && !code.contains(GS1Parser.GROUP_SEPARATOR)) {
        gtin = code;
      }

      Medicine? medicine = await _firestoreService.getMedicine(gtin, serial);
      foundMedicine.value = medicine;

      if (medicine != null) {
        if (medicine.status == 'Sold') {
          statusMessage.value = 'Already marked as Sold';
        } else {
          statusMessage.value = 'Ready to mark as Sold';
        }
      } else {
        statusMessage.value = 'Medicine not found in registry';
      }

      // Show sell screen
      currentStep.value = 2;
    } catch (e) {
      statusMessage.value = 'Error: $e';
      currentStep.value = 2; // Show error on sell screen
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsSold() async {
    final medicine = foundMedicine.value;
    final userId = _authService.currentUser.value?.uid;

    if (medicine == null || userId == null) {
      Get.snackbar('Error', 'No medicine scanned or user not logged in');
      return;
    }

    if (medicine.status == 'Sold') {
      Get.snackbar('Info', 'This medicine is already marked as Sold');
      return;
    }

    try {
      isUpdating.value = true;
      await _firestoreService.updateMedicineStatus(
        medicine.gtin,
        medicine.serialNumber,
        'Sold',
        userId,
      );

      final updatedMedicine = await _firestoreService.getMedicine(
        medicine.gtin,
        medicine.serialNumber,
      );
      foundMedicine.value = updatedMedicine;
      saleCompleted.value = true;
      statusMessage.value = 'Sale recorded successfully!';

      Get.snackbar(
        'Success',
        'Medicine marked as Sold',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update: $e');
      statusMessage.value = 'Update failed: $e';
    } finally {
      isUpdating.value = false;
    }
  }

  void resetScan() {
    resetScanState();
    // Scanner is already active in background
  }

  void resetScanState() {
    lastDetectedCode.value = '';
    foundMedicine.value = null;
    statusMessage.value = 'Scan medicine to mark as sold';
    saleCompleted.value = false;
    currentStep.value = 0;
  }
}
