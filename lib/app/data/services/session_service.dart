import 'dart:async';
import 'package:get/get.dart';
import 'auth_service.dart';

class SessionService extends GetxService {
  Timer? _timer;

  // Timeout duration - 15 minutes of inactivity
  static const Duration _timeout = Duration(minutes: 15);

  final AuthService _authService = Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    // Start tracking when the service is initialized
    _startTimer();

    // Listen to user auth state changes.
    // If user logs out, we should cancel the timer.
    // If user logs in, we should start the timer.
    ever(_authService.currentAppUser, (user) {
      if (user == null) {
        _cancelTimer();
      } else {
        resetTimer();
      }
    });
  }

  void _startTimer() {
    if (_authService.currentAppUser.value == null) return;

    _cancelTimer();
    _timer = Timer(_timeout, () {
      _handleTimeout();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resetTimer() {
    // Only reset if user is logged in
    if (_authService.currentAppUser.value != null) {
      _startTimer();
    }
  }

  void _handleTimeout() {
    print(
      'DEBUG [SessionService]: User inactive for ${_timeout.inMinutes} minutes. Logging out.',
    );
    _authService.signOut();
    Get.snackbar(
      'Session Expired',
      'You have been logged out due to inactivity.',
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void onClose() {
    _cancelTimer();
    super.onClose();
  }
}
