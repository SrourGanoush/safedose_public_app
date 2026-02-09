import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
// import 'firebase_options.dart'; // User needs to generate this
import 'app/data/services/firestore_service.dart';
import 'app/data/services/gemini_service.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/local_history_service.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/session_service.dart';
import 'app/data/services/tts_service.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera initialization failed: $e');
  }
  // IMPORTANT: The user must add their google-services.json / GoogleService-Info.plist
  // or use the FlutterFire CLI to generate firebase_options.dart.
  // For now, we attempt to init. If no options are found and no config file exists, this crashes.
  // To be safe in a "blind" environment, verify if we can proceed.
  // Assuming user will configure Firebase.
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // Dependency Injection
  Get.put(FirestoreService());
  Get.put(AuthService());
  Get.put(GeminiService());
  Get.put(SessionService()); // Register SessionService
  Get.put(TtsService()); // Register TtsService
  await Get.putAsync(() => LocalHistoryService().init());

  runApp(const SafeDoseApp());
}

class SafeDoseApp extends StatelessWidget {
  const SafeDoseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SafeDose',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: const Color(
            0xFF1976D2,
          ), // Slightly darker blue for better contrast
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.comfortable,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: const TextStyle(fontSize: 18),
          hintStyle: const TextStyle(fontSize: 16),
        ),
      ),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) => Get.find<SessionService>().resetTimer(),
          onPointerMove: (_) => Get.find<SessionService>().resetTimer(),
          onPointerUp: (_) => Get.find<SessionService>().resetTimer(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
