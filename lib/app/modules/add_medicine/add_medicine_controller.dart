import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/medicine.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/gemini_service.dart';
import '../../data/utils/gs1_parser.dart';
import '../home/home_controller.dart';
import 'barcode_scanner_page.dart';

class AddMedicineController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();
  final GeminiService _geminiService = Get.find<GeminiService>();

  final formKey = GlobalKey<FormState>();

  final gtinController = TextEditingController();
  final batchController = TextEditingController();
  final serialController = TextEditingController();
  final manufacturerController = TextEditingController();

  // Date picker handling could be added, simplifying for now
  var expiryDate = DateTime.now().add(const Duration(days: 365)).obs;
  var codeType = ''.obs;

  var isLoading = false.obs;

  Future<void> saveMedicine() async {
    if (!formKey.currentState!.validate()) return;

    final userId = _authService.currentUser.value?.uid;
    if (userId == null) {
      Get.snackbar('Error', 'You must be logged in to add medicine');
      return;
    }

    isLoading.value = true;
    try {
      final med = Medicine(
        gtin: gtinController.text,
        batchNumber: batchController.text,
        serialNumber: serialController.text,
        expiryDate: expiryDate.value,
        companyId: _authService.currentAppUser.value?.companyId ?? "",
        manufacturerName: manufacturerController.text,
        createdAt: DateTime.now(),
        distributorId: userId, // Link medicine to distributor
        status: 'Created',
        codeType: codeType.value,
        statusHistory: [
          {
            'status': 'Created',
            'timestamp': DateTime.now().toIso8601String(),
            'updatedBy': userId,
          },
        ],
      );

      await _firestoreService.addMedicine(med);
      Get.back();
      Get.snackbar(
        'Success',
        'Medicine added to ledger',
        backgroundColor: Colors.greenAccent,
        colorText: Colors.black,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expiryDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      expiryDate.value = picked;
    }
  }

  Future<void> scanBarcode() async {
    // Stop the home scanner if it exists to free the camera
    try {
      final homeController = Get.find<HomeController>();
      homeController.isScanning.value = false;
      await homeController.scannerController.stop();
      // Give time for camera release
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (_) {
      // HomeController might not exist, that's fine
    }

    // Use the new proper StatefulWidget scanner page
    final dynamic result = await Get.to(() => const BarcodeScannerPage());

    // Add a delay to ensure the scanner page's camera is fully disposed
    // before we try to restart the home scanner.
    await Future.delayed(const Duration(milliseconds: 500));

    // NOTE: We do NOT restart the home scanner here.
    // The user is still on the 'Register Medicine' tab.
    // The home scanner should only start when they switch back to the 'Verify Medicine' tab
    // which is handled by DashboardController.
    // Restarting it here would run the camera without a preview surface (BufferQueue error).

    if (result != null) {
      if (result is String) {
        _populateFromCode(result);
      } else if (result is Uint8List) {
        _aiExtractFromImage(result);
      }
    }
  }

  Future<void> _aiExtractFromImage(Uint8List image) async {
    isLoading.value = true;
    try {
      final details = await _geminiService.extractMedicineDetails(image);
      if (details.isNotEmpty) {
        if (details.containsKey('gtin')) {
          gtinController.text = details['gtin']!;
        }
        if (details.containsKey('serial')) {
          serialController.text = details['serial']!;
        }
        if (details.containsKey('batch'))
          batchController.text = details['batch']!;
        if (details.containsKey('name'))
          manufacturerController.text = details['name']!;
        if (details.containsKey('expiry')) {
          try {
            expiryDate.value = DateTime.parse(details['expiry']!);
          } catch (_) {}
        }
        if (details.containsKey('codeType')) {
          codeType.value = details['codeType']!;
        }

        Get.snackbar(
          'AI Extraction Success',
          'Medicine details populated from photo.',
          backgroundColor: Colors.greenAccent,
          colorText: Colors.black,
        );
      } else {
        Get.snackbar(
          'Extraction Failed',
          'AI could not read details from this photo.',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'AI extraction failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _populateFromCode(String code) {
    // Use GS1 Parser for robust extraction
    final gs1Data = GS1Parser.parse(code);
    String gtin = gs1Data['gtin'] ?? '';
    String serial = gs1Data['serial'] ?? '';
    String batch = gs1Data['batch'] ?? '';
    String expiryStr = gs1Data['expiry'] ?? '';

    // Fallback if no GS1 GTIN found
    if (gtin.isEmpty && !code.contains(GS1Parser.GROUP_SEPARATOR)) {
      gtin = code;
    }

    if (gtin.isNotEmpty) {
      gtinController.text = gtin;
      // Heuristic for manual population
      if (gtin.length == 13) {
        codeType.value = 'EAN-13';
      } else {
        codeType.value = 'GS1 DataMatrix'; // Default for other types
      }
    }
    if (serial.isNotEmpty) serialController.text = serial;
    if (batch.isNotEmpty) batchController.text = batch;

    if (expiryStr.isNotEmpty && expiryStr.length == 6) {
      // Parse YYMMDD
      try {
        int year = int.parse(expiryStr.substring(0, 2));
        int month = int.parse(expiryStr.substring(2, 4));
        int day = int.parse(expiryStr.substring(4, 6));
        // GS1 year logic: 50-99 = 1950-1999, 00-49 = 2000-2049 usually.
        // But for medicine expiry, it's usually future, so 20xx.
        // Let's assume 20xx for simplicity or sliding window.
        // A simple heuristic: if year < 50, assume 20xx, else 19xx (though unlikely for expiry)
        // Actually, for expiry, it's almost certainly 2000+.
        int fullYear = 2000 + year;

        // Handle "00" day which means end of month in some GS1 contexts?
        // Or if day is invalid. Standard DateTime handles it.
        expiryDate.value = DateTime(fullYear, month, day);
      } catch (_) {
        // Ignored, keep default
      }
    }

    Get.snackbar(
      'Scanned',
      'Fields populated from barcode. Please verify.',
      backgroundColor: Colors.blueAccent,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
