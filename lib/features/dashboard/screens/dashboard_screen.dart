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
  int _warningCount = 0;
  int _longestSessionMs = 0;
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
    final state = await NativeMonitoringService().getMonitoringState();
    final isRunning = state['isRunning'] ?? false;
    final warningCount = state['warningCount'] ?? 0;
    final longestSession = state['longestSession'] ?? 0;
    final stats = await NativeMonitoringService().getUsageStats();

    await LocalStorageService().syncNativeUsage(stats, warningCount);

    if (mounted) {
      setState(() {
        _isRunning = isRunning;
        _warningCount = warningCount;
        _longestSessionMs = longestSession;
        _usageStats = stats;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int ms) {
    final minutes = (ms / 60000).floor();
    final seconds = ((ms % 60000) / 1000).floor();
    return "${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    final settings = LocalStorageService().getSettings();
    final targetApps = settings?.targetApps ?? [];
    
    // Calculate total usage today
    int totalUsageMs = 0;
    _usageStats.forEach((key, value) {
      totalUsageMs += value;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Doomscroll Guard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Mindful Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isRunning 
                                ? AppColors.primaryAccent.withOpacity(0.12)
                                : Colors.grey.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRunning ? Icons.shield_rounded : Icons.shield_outlined,
                            size: 32,
                            color: _isRunning ? AppColors.primaryAccent : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isRunning ? 'Sistem Aktif' : 'Sistem Nonaktif',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isRunning 
                                    ? 'Memantau scrolling habits Anda secara real-time.' 
                                    : 'Aktifkan pemantauan untuk menjaga kesehatan digital.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRunning ? Colors.white : AppColors.primaryAccent,
                          foregroundColor: _isRunning ? Colors.red.shade700 : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: _isRunning 
                                ? BorderSide(color: Colors.red.shade100, width: 1.5)
                                : BorderSide.none,
                          ),
                        ),
                        onPressed: () async {
                          if (_isRunning) {
                            await NativeMonitoringService().stopService();
                          } else {
                            final settings = LocalStorageService().getSettings();
                            await NativeMonitoringService().startService(
                              settings?.targetApps ?? [],
                              settings?.thresholdMinutes ?? 20,
                            );
                          }
                          _fetchState(); // forcefully update state
                        },
                        child: Text(
                          _isRunning ? 'Hentikan Pemantauan' : 'Mulai Pemantauan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _isRunning ? Colors.red.shade700 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. Quick Stats Section
              const Text(
                'Ringkasan Hari Ini',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Stat 1: Total Screen Time
                  Expanded(
                    child: _buildStatCard(
                      label: 'Screen Time',
                      value: _formatDuration(totalUsageMs),
                      icon: Icons.hourglass_empty_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stat 2: Warnings
                  Expanded(
                    child: _buildStatCard(
                      label: 'Intervensi',
                      value: '$_warningCount Kali',
                      icon: Icons.notification_important_outlined,
                      accentColor: AppColors.secondaryAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stat 3: Longest Session
                  Expanded(
                    child: _buildStatCard(
                      label: 'Sesi Terlama',
                      value: _formatDuration(_longestSessionMs),
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 3. App Usage Progress List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Durasi Penggunaan Sesi Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Batas: 10s',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_usageStats.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surface, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada aktivitas scrolling terdeteksi.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ..._usageStats.entries.map((e) {
                  final appLabel = e.key.split('.').last;
                  // Threshold for testing is 10 seconds (10000ms)
                  final double progress = (e.value / 10000.0).clamp(0.0, 1.0);
                  final bool isCloseToLimit = progress >= 0.8;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  appLabel.isNotEmpty ? appLabel[0].toUpperCase() : 'A',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryAccent,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(e.value),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isCloseToLimit 
                                    ? AppColors.secondaryAccent 
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.background,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCloseToLimit 
                                  ? AppColors.secondaryAccent 
                                  : AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    Color? accentColor,
  }) {
    final themeColor = accentColor ?? AppColors.primaryAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: themeColor,
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
