import 'dart:async';
import 'dart:convert';
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
  Map<String, String> _appNamesMap = {};
  Map<String, String> _appIconsMap = {};
  Map<String, int> _activeSessions = {};
  bool _isQuietHoursActive = false;
  int _quietHoursStart = -1;
  int _quietHoursEnd = -1;
  List<String> _whitelistApps = [];
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _loadAppMetaData();
    _startPolling();
  }

  Future<void> _loadAppMetaData() async {
    try {
      final apps = await NativeMonitoringService().getInstalledApps();
      final Map<String, String> appNames = {};
      final Map<String, String> appIcons = {};
      for (final app in apps) {
        final pkg = app['packageName'];
        final name = app['appName'];
        final icon = app['appIcon'];
        if (pkg != null) {
          if (name != null) appNames[pkg] = name;
          if (icon != null) appIcons[pkg] = icon;
        }
      }
      if (mounted) {
        setState(() {
          _appNamesMap = appNames;
          _appIconsMap = appIcons;
        });
      }
    } catch (e) {
      debugPrint("Error loading app metadata: $e");
    }
  }

  void _startPolling() {
    _fetchState(); // fetch immediately
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchState());
  }

  Future<void> _fetchState() async {
    final state = await NativeMonitoringService().getMonitoringState();
    final isRunning = state['isRunning'] ?? false;
    final isPaused = state['isPaused'] ?? false;
    final warningCount = state['warningCount'] ?? 0;
    final longestSession = state['longestSession'] ?? 0;
    final stats = await NativeMonitoringService().getUsageStats();

    final Map<String, int> typedStats = {};
    stats.forEach((key, value) {
      typedStats[key.toString()] = (value as num).toInt();
    });

    final activeSessionsRaw = state['activeSessions'] as Map?;
    final Map<String, int> activeSessions = {};
    if (activeSessionsRaw != null) {
      activeSessionsRaw.forEach((key, value) {
        final duration = (value as num).toInt();
        if (duration > 0) {
          activeSessions[key.toString()] = duration;
        }
      });
    }

    final isQuietHoursActive = state['isQuietHoursActive'] ?? false;
    final quietHoursStart = state['quietHoursStart'] ?? -1;
    final quietHoursEnd = state['quietHoursEnd'] ?? -1;
    final whitelistAppsRaw = state['whitelistApps'] as List?;
    final List<String> whitelistApps =
        whitelistAppsRaw?.map((e) => e.toString()).toList() ?? [];

    await LocalStorageService().syncNativeUsage(typedStats, warningCount);

    if (mounted) {
      setState(() {
        _isRunning = isRunning;
        _isPaused = isPaused;
        _warningCount = warningCount;
        _longestSessionMs = longestSession;
        _usageStats = typedStats;
        _activeSessions = activeSessions;
        _isQuietHoursActive = isQuietHoursActive;
        _quietHoursStart = quietHoursStart;
        _quietHoursEnd = quietHoursEnd;
        _whitelistApps = whitelistApps;
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

  String _formatMinutes(int minutes) {
    if (minutes < 0) return '--:--';
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  @override
  Widget build(BuildContext context) {
    final settings = LocalStorageService().getSettings();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Calculate total usage today
    int totalUsageMs = 0;
    _usageStats.forEach((key, value) {
      totalUsageMs += value;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Doomscroll Guard',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
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
                            _isRunning
                                ? (_isPaused
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.shield_rounded)
                                : Icons.shield_outlined,
                            size: 32,
                            color: _isRunning
                                ? (_isPaused
                                      ? Colors.orange.shade700
                                      : AppColors.primaryAccent)
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isRunning
                                    ? (_isPaused
                                          ? 'Pemantauan Dijeda'
                                          : 'Sistem Aktif')
                                    : 'Sistem Nonaktif',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isRunning
                                    ? (_isPaused
                                          ? 'Perlindungan layar sedang ditangguhkan.'
                                          : 'Memantau kebiasaan scrolling Anda secara real-time.')
                                    : 'Aktifkan pemantauan untuk menjaga kesehatan digital.',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isRunning &&
                        ((_quietHoursStart != -1 && _quietHoursEnd != -1) ||
                            _whitelistApps.isNotEmpty)) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.start,
                          children: [
                            if (_quietHoursStart != -1 && _quietHoursEnd != -1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _isQuietHoursActive
                                      ? AppColors.secondaryAccent.withOpacity(
                                          0.14,
                                        )
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: _isQuietHoursActive
                                        ? AppColors.secondaryAccent.withOpacity(
                                            0.32,
                                          )
                                        : AppColors.surface,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isQuietHoursActive
                                          ? Icons.nights_stay_rounded
                                          : Icons.nights_stay_outlined,
                                      size: 14,
                                      color: _isQuietHoursActive
                                          ? AppColors.secondaryAccent
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isQuietHoursActive
                                          ? 'Jam Tenang Aktif'
                                          : 'Jam Tenang (${_formatMinutes(_quietHoursStart)} - ${_formatMinutes(_quietHoursEnd)})',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: _isQuietHoursActive
                                            ? AppColors.secondaryAccent
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_whitelistApps.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted.withOpacity(
                                    0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: AppColors.surface.withOpacity(0.7),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: AppColors.secondaryAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_whitelistApps.length} Aplikasi Pengecualian',
                                      style: textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isRunning
                              ? AppColors.primaryAccent
                              : (_isPaused
                                    ? AppColors.primaryAccent
                                    : AppColors.surface),
                          foregroundColor: !_isRunning
                              ? Colors.white
                              : (_isPaused
                                    ? Colors.white
                                    : AppColors.textPrimary),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: _isRunning && !_isPaused
                                ? BorderSide(
                                    color: AppColors.surface.withOpacity(0.8),
                                    width: 1.5,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        onPressed: () async {
                          if (!_isRunning) {
                            final settings = LocalStorageService()
                                .getSettings();
                            await NativeMonitoringService().startService(
                              targetApps: settings?.targetApps ?? [],
                              thresholdMinutes:
                                  settings?.thresholdMinutes ?? 20,
                              whitelistApps: settings?.whitelistApps ?? [],
                              quietHoursStartMinutes:
                                  settings?.quietHoursStartMinutes ?? -1,
                              quietHoursEndMinutes:
                                  settings?.quietHoursEndMinutes ?? -1,
                            );
                          } else {
                            if (_isPaused) {
                              await NativeMonitoringService()
                                  .setMonitoringPaused(false);
                            } else {
                              await NativeMonitoringService()
                                  .setMonitoringPaused(true);
                            }
                          }
                          _fetchState(); // forcefully update state
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isRunning) ...[
                              Icon(
                                _isPaused
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.pause_circle_filled_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              !_isRunning
                                  ? 'Mulai Pemantauan'
                                  : (_isPaused
                                        ? 'Lanjutkan Pemantauan'
                                        : 'Jeda Pemantauan'),
                              style: textTheme.labelLarge?.copyWith(
                                color: !_isRunning
                                    ? Colors.white
                                    : (_isPaused
                                          ? Colors.white
                                          : AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. Quick Stats Section
              Text(
                'Ringkasan Hari Ini',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
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
                  Text(
                    'Durasi Penggunaan Sesi Ini',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Batas: ${settings?.thresholdMinutes == 0 ? "10s" : "${settings?.thresholdMinutes ?? 20}m"}',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_activeSessions.isEmpty || _isPaused)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surface, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      _isPaused
                          ? 'Pemantauan sedang dijeda.'
                          : 'Belum ada aktivitas scrolling terdeteksi.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ..._activeSessions.entries.map((e) {
                  final appLabel = _getCleanAppName(e.key);
                  final int thresholdMinutes = settings?.thresholdMinutes ?? 20;
                  final double limitMs = thresholdMinutes == 0
                      ? 10000.0
                      : (thresholdMinutes * 60 * 1000).toDouble();
                  final double progress = (e.value / limitMs).clamp(0.0, 1.0);
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
                            _buildAppIcon(e.key),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appLabel,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    e.key,
                                    style: textTheme.bodySmall?.copyWith(
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
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w700,
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
          Icon(icon, size: 20, color: themeColor),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getCleanAppName(String packageName) {
    if (_appNamesMap.containsKey(packageName)) {
      return _appNamesMap[packageName]!;
    }
    // Fallbacks
    if (packageName == 'com.instagram.android') return 'Instagram';
    if (packageName == 'com.zhiliaoapp.musically') return 'TikTok';

    final parts = packageName.split('.');
    if (parts.length >= 2) {
      final candidate = parts[parts.length - 2];
      if (candidate.toLowerCase() != 'com' &&
          candidate.toLowerCase() != 'android') {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }
    final label = parts.last;
    return label[0].toUpperCase() + label.substring(1);
  }

  Widget _buildAppIcon(String packageName) {
    final base64Icon = _appIconsMap[packageName];
    if (base64Icon != null && base64Icon.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            base64Decode(base64Icon),
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
        );
      } catch (e) {
        // fallback
      }
    }
    final cleanName = _getCleanAppName(packageName);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'A',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryAccent,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
