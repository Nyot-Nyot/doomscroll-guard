import 'dart:async';
import 'package:flutter/material.dart';
import 'package:doomscrolling_guard/core/services/native_monitoring_service.dart';
import 'package:doomscrolling_guard/core/services/local_storage_service.dart';
import 'package:doomscrolling_guard/core/themes/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isRunning = false;
  Map<String, int> _usageStats = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _fetchState(); // fetch immediately
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchState());
  }

  Future<void> _fetchState() async {
    final isRunning = await NativeMonitoringService().getMonitoringState();
    final stats = await NativeMonitoringService().getUsageStats();
    if (mounted) {
      setState(() {
        _isRunning = isRunning;
        _usageStats = stats;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
            Icon(
              _isRunning ? Icons.shield_rounded : Icons.shield_outlined,
              size: 80, 
              color: _isRunning ? AppColors.primaryAccent : Colors.grey,
            ),
            const SizedBox(height: 32),
            Text(
              _isRunning ? 'Monitoring Active' : 'Monitoring Stopped', 
              style: Theme.of(context).textTheme.headlineMedium
            ),
            const SizedBox(height: 24),
            // Usage stats display
            if (_usageStats.isNotEmpty) ...[
              const Text("Today's Usage (Fallback + Internal):", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._usageStats.entries.map((e) => Text("${e.key}: ${(e.value / 1000).toStringAsFixed(1)} detik")),
              const SizedBox(height: 24),
            ],
            if (!_isRunning)
              ElevatedButton(
                onPressed: () async {
                  final settings = LocalStorageService().getSettings();
                  await NativeMonitoringService().startService(
                    settings?.targetApps ?? [],
                    settings?.thresholdMinutes ?? 20,
                  );
                  _fetchState(); // forcefully update state
                },
                child: const Text('Start Foreground Service'),
              ),
            if (_isRunning)
              TextButton(
                onPressed: () async {
                  await NativeMonitoringService().stopService();
                  _fetchState();
                },
                child: const Text('Stop Foreground Service', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
