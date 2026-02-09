import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../dashboard/dashboard_controller.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/medicine.dart';
import '../../data/utils/gs1_parser.dart';

class PharmacyScanController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final DashboardController _dashboardController =
      Get.find<DashboardController>();

  // Use the shared scanner from DashboardController
  MobileScannerController get scannerController {
    if (_dashboardController.sharedScanner == null) {
      // Fallback if accessed incorrectly, though unlikely with proper flow
      return MobileScannerController();
    }
    return _dashboardController.sharedScanner!;
  }

  // States
  var currentStep = 0.obs; // 0 = camera preview, 1 = verifying, 2 = results
  var lastDetectedCode = ''.obs;
  var verificationStatus = ''.obs;
  var foundMedicine = Rxn<Medicine>();
  var isLoading = false.obs;

  // Removed onReady manual start to rely on shared scanner state

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

    // Start verification (scanner stays active but hidden)
    currentStep.value = 1; // Verifying
    isLoading.value = true;
    verificationStatus.value = 'Verifying medicine...';

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
        verificationStatus.value = 'Medicine Found ✓';
      } else {
        verificationStatus.value = 'Not Found in Registry';
      }

      // Show results screen
      currentStep.value = 2;
    } catch (e) {
      verificationStatus.value = 'Error: $e';
      currentStep.value = 2; // Still show results with error
    } finally {
      isLoading.value = false;
    }
  }

  // Reset to camera preview
  void resetScan() {
    resetScanState();
    // Scanner is already running, just reset state
  }

  void resetScanState() {
    lastDetectedCode.value = '';
    foundMedicine.value = null;
    verificationStatus.value = '';
    currentStep.value = 0;
  }
}
