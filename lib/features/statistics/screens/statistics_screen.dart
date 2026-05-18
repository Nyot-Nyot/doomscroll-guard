import 'package:flutter/material.dart';
import 'package:doomscrolling_guard/core/services/local_storage_service.dart';
import 'package:doomscrolling_guard/core/services/native_monitoring_service.dart';
import 'package:doomscrolling_guard/core/themes/app_colors.dart';
import 'package:doomscrolling_guard/shared/models/daily_usage.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late List<DateTime> _last7Days;
  List<DailyUsage?> _dailyUsageHistory = [];
  bool _isLoading = true;
  Map<String, String> _appNamesMap = {};

  @override
  void initState() {
    super.initState();
    _loadAppMetaData();
    _loadHistory();
  }

  Future<void> _loadAppMetaData() async {
    try {
      final apps = await NativeMonitoringService().getInstalledApps();
      final Map<String, String> appNames = {};
      for (final app in apps) {
        final pkg = app['packageName'];
        final name = app['appName'];
        if (pkg != null && name != null) {
          appNames[pkg] = name;
        }
      }
      if (mounted) {
        setState(() {
          _appNamesMap = appNames;
        });
      }
    } catch (e) {
      debugPrint("Error loading app metadata: $e");
    }
  }

  void _loadHistory() {
    final today = DateTime.now();
    _last7Days = List.generate(7, (index) {
      return DateTime(today.year, today.month, today.day).subtract(Duration(days: index));
    }).reversed.toList();

    final allUsage = LocalStorageService().getAllDailyUsage();
    final List<DailyUsage?> history = [];

    for (final date in _last7Days) {
      DailyUsage? match;
      for (final usage in allUsage) {
        if (usage.date.year == date.year &&
            usage.date.month == date.month &&
            usage.date.day == date.day) {
          match = usage;
          break;
        }
      }
      history.add(match);
    }

    if (mounted) {
      setState(() {
        _dailyUsageHistory = history;
        _isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return "0s";
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    if (minutes <= 0) {
      return "${remainingSeconds}s";
    }
    return "${minutes}m ${remainingSeconds}s";
  }

  String _getWeekdayLabel(DateTime date) {
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return "Hari Ini";
    }
    // Localized short weekday name
    const weekdays = ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"];
    return "${weekdays[date.weekday % 7]} ${date.day}/${date.month}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
      );
    }

    // Calculate today's stats from the last item in history (today)
    final todayUsage = _dailyUsageHistory.last;
    int todayTotalSeconds = 0;
    String topAppLabel = "Tidak Ada";
    int topAppSeconds = 0;
    int todayWarningCount = todayUsage?.warningCount ?? 0;

    if (todayUsage != null && todayUsage.usageSecondsByApp.isNotEmpty) {
      todayUsage.usageSecondsByApp.forEach((app, seconds) {
        todayTotalSeconds += seconds;
        if (seconds > topAppSeconds) {
          topAppSeconds = seconds;
          topAppLabel = _getCleanAppName(app);
        }
      });
    }

    // Find the maximum daily total usage in the last 7 days to scale progress bars dynamically
    int maxDailyTotalSeconds = 300; // minimum scale is 5 minutes (300 seconds) to prevent division by zero or super tiny bars
    for (final usage in _dailyUsageHistory) {
      if (usage != null) {
        int dailySum = 0;
        usage.usageSecondsByApp.values.forEach((sec) => dailySum += sec);
        if (dailySum > maxDailyTotalSeconds) {
          maxDailyTotalSeconds = dailySum;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Statistik',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadHistory();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiet Header Subtitle
              const Text(
                'Refleksi Mingguan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Menjaga kesadaran penuh akan kebiasaan layar tanpa rasa bersalah.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 1. Daily Hero Summary Card
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL SCREEN TIME HARI INI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatDuration(todayTotalSeconds),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.background, thickness: 1.5),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Left Stat: Top App
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Aplikasi Teraktif',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                topAppLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (topAppSeconds > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _formatDuration(topAppSeconds),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Divider
                        Container(
                          width: 1.5,
                          height: 50,
                          color: AppColors.background,
                        ),
                        const SizedBox(width: 24),
                        // Right Stat: Total Warnings
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pemberitahuan Peringatan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.notification_important_rounded,
                                    size: 20,
                                    color: todayWarningCount > 0 
                                        ? AppColors.secondaryAccent 
                                        : AppColors.primaryAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$todayWarningCount Kali',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // 2. Weekly Trend Graph Section
              const Text(
                'Tren Penggunaan 7 Hari Terakhir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(_last7Days.length, (index) {
                    final date = _last7Days[index];
                    final usage = _dailyUsageHistory[index];
                    
                    int dailySum = 0;
                    if (usage != null) {
                      usage.usageSecondsByApp.values.forEach((sec) => dailySum += sec);
                    }

                    final double progress = (dailySum / maxDailyTotalSeconds).clamp(0.0, 1.0);
                    final isToday = index == _last7Days.length - 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          // Left Side: Day Label
                          SizedBox(
                            width: 75,
                            child: Text(
                              _getWeekdayLabel(date),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? AppColors.primaryAccent : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Middle: Progress bar representing screen time
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: progress,
                                  child: Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: isToday 
                                          ? AppColors.primaryAccent 
                                          : AppColors.primaryAccent.withOpacity(0.65),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right Side: Duration Label
                          SizedBox(
                            width: 65,
                            child: Text(
                              _formatDuration(dailySum),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              // Mindful Advice Quote Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryAccent.withOpacity(0.12), width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.spa_rounded, color: AppColors.primaryAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Setiap kali Anda menaruh smartphone, Anda memberi ruang untuk kedamaian pikiran Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      if (candidate.toLowerCase() != 'com' && candidate.toLowerCase() != 'android') {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }
    final label = parts.last;
    return label[0].toUpperCase() + label.substring(1);
  }
}
