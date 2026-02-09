import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../home/home_controller.dart';
import '../pharmacy_scan/pharmacy_scan_controller.dart';
import '../pharmacy_sell/pharmacy_sell_controller.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';

class DashboardController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  var tabIndex = 0.obs;

  // Shared scanner for all tabs to prevent camera resource conflicts
  MobileScannerController? sharedScanner;

  // Get current user role
  UserRole? get currentUserRole => _authService.currentAppUser.value?.role;
  bool get isPharmacy => currentUserRole == UserRole.pharmacy;
  bool get isDistributor => currentUserRole == UserRole.distributor;
  bool get isUser =>
      currentUserRole == UserRole.user || currentUserRole == null;

  @override
  void onInit() {
    super.onInit();
    print(
      'DEBUG [DashboardController]: Initializing. User Role: $currentUserRole, isPharmacy: $isPharmacy',
    );

    // Initialize shared scanner for all roles to ensure stability
    sharedScanner = MobileScannerController(
      autoStart: true, // Start immediately to be ready for views
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [
        BarcodeFormat.dataMatrix,
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
      ],
    );
  }

  void logout() async {
    await _authService.signOut();
  }

  void changeTabIndex(int index) async {
    if (isPharmacy) {
      _handlePharmacyTabChange(index);
      tabIndex.value = index;
    } else if (isDistributor) {
      await _handleDistributorTabChange(index);
    } else {
      await _handleUserTabChange(index);
    }
  }

  void _handlePharmacyTabChange(int index) {
    // When switching tabs, we just reset the state of the controllers
    // The camera resource (pharmacyScanner) stays alive in this controller
    if (index == 0) {
      try {
        final scanController = Get.find<PharmacyScanController>();
        scanController.resetScanState();
      } catch (_) {}
    } else if (index == 1) {
      try {
        final sellController = Get.find<PharmacySellController>();
        sellController.resetScanState();
      } catch (_) {}
    }
  }

  Future<void> _handleDistributorTabChange(int index) async {
    final oldIndex = tabIndex.value;

    // Case 1: Leaving Home (Scanner) -> Stop scanner, THEN switch tab
    if (oldIndex == 0 && index != 0) {
      await _stopHomeScanner();
      tabIndex.value = index;
    }
    // Case 2: Returning to Home (Scanner) -> Switch tab (Mount), THEN start scanner
    else if (oldIndex != 0 && index == 0) {
      tabIndex.value = index;
      // Allow time for the View to mount the MobileScanner widget
      await Future.delayed(const Duration(milliseconds: 200));
      await _startHomeScanner();
    }
    // Case 3: Other tab changes
    else {
      tabIndex.value = index;
    }
  }

  Future<void> _handleUserTabChange(int index) async {
    final oldIndex = tabIndex.value;

    // Case 1: Leaving Home (Scanner) -> Stop scanner, THEN switch tab
    if (oldIndex == 0 && index != 0) {
      await _stopHomeScanner();
      tabIndex.value = index;
    }
    // Case 2: Returning to Home (Scanner) -> Switch tab (Mount), THEN start scanner
    else if (oldIndex != 0 && index == 0) {
      tabIndex.value = index;
      // Allow time for the View to mount the MobileScanner widget
      await Future.delayed(const Duration(milliseconds: 200));
      await _startHomeScanner();
    }
    // Case 3: Other tab changes
    else {
      tabIndex.value = index;
    }
  }

  Future<void> _stopHomeScanner() async {
    try {
      final homeController = Get.find<HomeController>();
      homeController.isScanning.value = false;
      await homeController.scannerController.stop();
      // Add a small delay to ensure the camera resource is fully released
      await Future.delayed(const Duration(milliseconds: 200));
      await homeController.disposeCamera();
    } catch (_) {}
  }

  Future<void> _startHomeScanner() async {
    try {
      final homeController = Get.find<HomeController>();
      homeController.isScanning.value = true;
      homeController.refreshScannerKey(); // Force rebuild
      await homeController.scannerController.start();
    } catch (_) {}
  }

  @override
  void onClose() {
    sharedScanner?.dispose();
    super.onClose();
  }
}
