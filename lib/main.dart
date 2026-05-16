import 'package:doomscrolling_guard/core/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:doomscrolling_guard/core/themes/app_theme.dart';
import 'package:doomscrolling_guard/features/onboarding/screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalStorageService().init();
    if (kDebugMode) {
      await LocalStorageService().seedIfEmpty();
    }
    debugPrint("Hive initialized successfully.");
  } catch (e, st) {
    debugPrint("Error initializing Hive: $e\n$st");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doomscroll Guard',
      theme: AppTheme.lightTheme,
      home: const OnboardingScreen(),
    );
  }
}
