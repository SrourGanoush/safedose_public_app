import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/auth_service.dart';
import '../../routes/app_pages.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    // If user is not logged in, redirect to Login
    if (authService.currentUser.value == null) {
      return const RouteSettings(name: Routes.LOGIN);
    }

    // If user hasn't completed role selection (AppUser not loaded yet or no role set)
    // We check if we're not already going to role selection to prevent loop
    final appUser = authService.currentAppUser.value;
    if (route != Routes.ROLE_SELECTION &&
        route != Routes.LOGIN &&
        appUser == null) {
      // AppUser hasn't loaded yet - allow through, they'll be redirected after load
      // Or we can show role selection for fresh users
      // For simplicity, let's assume if no appUser, they need role selection
      return const RouteSettings(name: Routes.ROLE_SELECTION);
    }

    return null;
  }
}
