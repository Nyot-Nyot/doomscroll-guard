import 'package:doomscrolling_guard/core/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doomscrolling_guard/core/themes/app_theme.dart';
import 'package:doomscrolling_guard/features/onboarding/screens/onboarding_screen.dart';
import 'package:doomscrolling_guard/features/onboarding/screens/app_picker_screen.dart';
import 'package:doomscrolling_guard/features/dashboard/screens/main_navigation_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
  );
  bool permissionsCompleted = false;
  bool targetAppsCompleted = false;

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
    
    final settings = LocalStorageService().getSettings();
    if (settings != null && settings.targetApps.isNotEmpty) {
      targetAppsCompleted = true;
    }
    
    debugPrint("Hive initialized successfully.");
  } catch (e, st) {
    debugPrint("Error initializing Hive: $e\n$st");
  }

  runApp(MyApp(
    permissionsCompleted: permissionsCompleted,
    targetAppsCompleted: targetAppsCompleted,
  ));
}

class MyApp extends StatelessWidget {
  final bool permissionsCompleted;
  final bool targetAppsCompleted;

  const MyApp({
    super.key,
    required this.permissionsCompleted,
    required this.targetAppsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doomscroll Guard',
      theme: AppTheme.lightTheme,
      home: permissionsCompleted
          ? (targetAppsCompleted
              ? const MainNavigationShell()
              : const AppPickerScreen())
          : const OnboardingScreen(),
    );
  }
}
