import 'package:doomscrolling_guard/core/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:doomscrolling_guard/core/themes/app_theme.dart';
import 'package:doomscrolling_guard/features/onboarding/screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool permissionsCompleted = false;

  try {
    await LocalStorageService().init();
    if (kDebugMode) {
      // await LocalStorageService().seedIfEmpty(); // Disabled so we can test onboarding
    }
    final perms = LocalStorageService().getPermissionState();
    if (perms != null) {
      permissionsCompleted = perms.accessibilityGranted &&
          perms.usageAccessGranted &&
          perms.overlayGranted &&
          perms.batteryOptimizationIgnored;
    }
    debugPrint("Hive initialized successfully.");
  } catch (e, st) {
    debugPrint("Error initializing Hive: $e\n$st");
  }

  runApp(MyApp(permissionsCompleted: permissionsCompleted));
}

class MyApp extends StatelessWidget {
  final bool permissionsCompleted;

  const MyApp({super.key, required this.permissionsCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doomscroll Guard',
      theme: AppTheme.lightTheme,
      home: permissionsCompleted
          ? const Scaffold(body: Center(child: Text("Dashboard (Next Major Task)")))
          : const OnboardingScreen(),
    );
  }
}
