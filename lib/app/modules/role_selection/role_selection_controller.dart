import 'package:get/get.dart';

import '../../data/services/auth_service.dart';
import '../../routes/app_pages.dart';

class RoleSelectionController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    // Check immediately when the controller is ready
    _checkRedirect();

    // Listen for any future changes to the user object
    ever(_authService.currentAppUser, (_) {
      _checkRedirect();
    });
  }

  void _checkRedirect() {
    if (_authService.currentAppUser.value != null) {
      // Avoid redirecting if we are already on the dashboard
      if (Get.currentRoute == Routes.DASHBOARD) return;

      // Small delay to ensure UI is built before navigating
      Future.delayed(const Duration(milliseconds: 100), () {
        // Double check inside the future to be safe
        if (Get.currentRoute != Routes.DASHBOARD) {
          Get.offAllNamed(Routes.DASHBOARD);
        }
      });
    }
  }
}
