import 'package:flutter/material.dart';
import 'package:doomscrolling_guard/core/services/native_monitoring_service.dart';
import 'package:doomscrolling_guard/core/themes/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doomscroll Guard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_rounded, size: 80, color: AppColors.primaryAccent),
            const SizedBox(height: 32),
            Text('Monitoring Service', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                NativeMonitoringService().startService();
              },
              child: const Text('Start Foreground Service'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                NativeMonitoringService().stopService();
              },
              child: const Text('Stop Foreground Service'),
            ),
          ],
        ),
      ),
    );
  }
}
