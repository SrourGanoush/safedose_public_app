import 'package:get/get.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';
import '../../routes/app_pages.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  var isLoading = false.obs;

  Future<void> loginAsDistributor() async {
    isLoading.value = true;
    await _authService.signInWithGoogle(desiredRole: UserRole.distributor);
    isLoading.value = false;
    _checkAuth();
  }

  Future<void> loginAsRegularUser() async {
    isLoading.value = true;
    await _authService.signInWithGoogle(desiredRole: UserRole.user);
    isLoading.value = false;
    _checkAuth();
  }

  Future<void> loginAsPharmacy() async {
    isLoading.value = true;
    await _authService.signInWithGoogle(desiredRole: UserRole.pharmacy);
    isLoading.value = false;
    _checkAuth();
  }

  void _checkAuth() async {
    if (_authService.currentUser.value != null) {
      print(
        'DEBUG [LoginController]: User authenticated, waiting for AppUser...',
      );

      // Wait for currentAppUser to be populated (max 10 seconds)
      int attempts = 0;
      while (_authService.currentAppUser.value == null && attempts < 100) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      final appUser = _authService.currentAppUser.value;
      if (appUser != null) {
        print(
          'DEBUG [LoginController]: AppUser loaded - Role: ${appUser.role}',
        );
        Get.offAllNamed(Routes.DASHBOARD);
      } else {
        print('DEBUG [LoginController]: ERROR - AppUser not loaded after 10s');
        Get.snackbar(
          'Error',
          'Failed to load user profile. Please check your connection.',
        );
        // Optional: Sign out if profile fails to load to prevent stuck state
        _authService.signOut();
      }
    }
  }
}
