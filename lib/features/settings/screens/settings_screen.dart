import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/native_monitoring_service.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../shared/models/settings.dart';
import '../widgets/app_picker_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Settings? _settings;
  bool _isTestMode = false;
  double _sliderValue = 20.0;
  Map<String, String> _appNamesMap = {};
  Map<String, String> _appIconsMap = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = LocalStorageService().getSettings();
    if (settings != null) {
      setState(() {
        _settings = settings;
        // 0 thresholdMinutes represents the 10-second testing mode
        _isTestMode = settings.thresholdMinutes == 0;
        _sliderValue = _isTestMode
            ? 20.0
            : settings.thresholdMinutes.toDouble().clamp(1.0, 60.0);
      });
    }

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
      debugPrint("Error caching app data: $e");
    }
  }

  Future<void> _saveSettings(Settings updatedSettings) async {
    await LocalStorageService().saveSettings(updatedSettings);
    setState(() {
      _settings = updatedSettings;
    });

    // Check if the native service is running, and synchronize config dynamically
    final state = await NativeMonitoringService().getMonitoringState();
    final isRunning = state['isRunning'] ?? false;
    if (isRunning) {
      await NativeMonitoringService().updateServiceConfig(
        targetApps: updatedSettings.targetApps,
        thresholdMinutes: updatedSettings.thresholdMinutes,
        whitelistApps: updatedSettings.whitelistApps,
        quietHoursStartMinutes: updatedSettings.quietHoursStartMinutes,
        quietHoursEndMinutes: updatedSettings.quietHoursEndMinutes,
      );
    }
  }

  void _showAppPicker() {
    if (_settings == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppPickerSheet(
        title: 'Pilih Aplikasi Target',
        initialSelectedApps: _settings!.targetApps,
        onSaved: (selectedApps) {
          final updated = _settings!.copyWith(targetApps: selectedApps);
          _saveSettings(updated);
        },
      ),
    );
  }

  void _showWhitelistAppPicker() {
    if (_settings == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppPickerSheet(
        title: 'Pilih Aplikasi Whitelist',
        initialSelectedApps: _settings!.whitelistApps,
        onSaved: (selectedApps) {
          final updated = _settings!.copyWith(whitelistApps: selectedApps);
          _saveSettings(updated);
        },
      ),
    );
  }

  TimeOfDay _minutesToTime(int minutes) {
    if (minutes < 0) return const TimeOfDay(hour: 22, minute: 0);
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (_settings == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
          ),
        ),
      );
    }

    final targetApps = _settings!.targetApps;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Pengaturan Batas',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sesuaikan batas waktu dan aplikasi yang dipantau agar kebiasaan digital Anda tetap sehat.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Card 1: Threshold Configuration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.speed_rounded,
                              color: AppColors.primaryAccent,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Batas Sesi Kontinu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isTestMode
                                ? AppColors.secondaryAccent.withOpacity(0.12)
                                : AppColors.primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isTestMode
                                ? '10 Detik'
                                : '${_sliderValue.round()} Menit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isTestMode
                                  ? AppColors.secondaryAccent
                                  : AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih seberapa lama Anda diizinkan melakukan scrolling tanpa henti sebelum peringatan intervensi muncul.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Test Mode Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode Uji Coba (10 Detik)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Gunakan batas 10 detik agar mudah dites.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isTestMode,
                          activeColor: AppColors.primaryAccent,
                          onChanged: (value) {
                            setState(() {
                              _isTestMode = value;
                              final updatedMinutes = value
                                  ? 0
                                  : _sliderValue.round();
                              _saveSettings(
                                _settings!.copyWith(
                                  thresholdMinutes: updatedMinutes,
                                ),
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Slider (Disabled during Test Mode)
                    Opacity(
                      opacity: _isTestMode ? 0.35 : 1.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primaryAccent,
                              inactiveTrackColor: AppColors.surface.withOpacity(
                                0.5,
                              ),
                              thumbColor: AppColors.primaryAccent,
                              overlayColor: AppColors.primaryAccent.withOpacity(
                                0.12,
                              ),
                              valueIndicatorColor: AppColors.primaryAccent,
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _sliderValue,
                              min: 1.0,
                              max: 60.0,
                              divisions: 59,
                              label: '${_sliderValue.round()} Menit',
                              onChanged: _isTestMode
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _sliderValue = value;
                                      });
                                    },
                              onChangeEnd: _isTestMode
                                  ? null
                                  : (value) {
                                      final updated = _settings!.copyWith(
                                        thresholdMinutes: value.round(),
                                      );
                                      _saveSettings(updated);
                                    },
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '1m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '15m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '30m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '45m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '60m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Card 2: Monitored Apps
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.apps_rounded,
                          color: AppColors.primaryAccent,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Aplikasi Terpantau',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ada ${targetApps.length} aplikasi terpilih yang dipantau durasi sesi doomscrolling-nya.',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Initial list
                    if (targetApps.isNotEmpty) ...[
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: targetApps.length,
                          itemBuilder: (context, index) {
                            final pkg = targetApps[index];
                            final cleanName = _getCleanAppName(pkg);

                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSmallAppIcon(pkg),
                                  const SizedBox(width: 8),
                                  Text(
                                    cleanName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _showAppPicker,
                        child: const Text(
                          'Atur Aplikasi Target',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card 3: Whitelisted / Exception Apps
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.primaryAccent,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Aplikasi Pengecualian',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aplikasi terpilih tidak akan memicu peringatan intervensi meskipun durasi scrolling terlampaui.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Initial list
                    if (_settings!.whitelistApps.isNotEmpty) ...[
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _settings!.whitelistApps.length,
                          itemBuilder: (context, index) {
                            final pkg = _settings!.whitelistApps[index];
                            final cleanName = _getCleanAppName(pkg);

                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildSmallAppIcon(pkg),
                                  const SizedBox(width: 8),
                                  Text(
                                    cleanName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _showWhitelistAppPicker,
                        child: const Text(
                          'Atur Aplikasi Whitelist',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card 4: Quiet Hours (Jam Tenang)
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.nights_stay_rounded,
                                color: AppColors.primaryAccent,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Jam Tenang (Quiet Hours)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _settings!.quietHoursStartMinutes != -1,
                          activeColor: AppColors.primaryAccent,
                          onChanged: (value) {
                            if (value) {
                              // Enable with default 22:00 - 06:00 (1320 - 360)
                              final updated = _settings!.copyWith(
                                quietHoursStartMinutes: 1320,
                                quietHoursEndMinutes: 360,
                              );
                              _saveSettings(updated);
                            } else {
                              // Disable quiet hours (-1, -1)
                              final updated = _settings!.copyWith(
                                quietHoursStartMinutes: -1,
                                quietHoursEndMinutes: -1,
                              );
                              _saveSettings(updated);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Jeda peringatan intervensi secara otomatis pada rentang waktu yang Anda tentukan.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_settings!.quietHoursStartMinutes != -1) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final initialTime = _minutesToTime(
                                  _settings!.quietHoursStartMinutes,
                                );
                                final selected = await showTimePicker(
                                  context: context,
                                  initialTime: initialTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: AppColors.primaryAccent,
                                          onPrimary: Colors.white,
                                          onSurface: AppColors.textPrimary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (selected != null) {
                                  final updated = _settings!.copyWith(
                                    quietHoursStartMinutes: _timeToMinutes(
                                      selected,
                                    ),
                                  );
                                  _saveSettings(updated);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mulai',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatMinutes(
                                        _settings!.quietHoursStartMinutes,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final initialTime = _minutesToTime(
                                  _settings!.quietHoursEndMinutes,
                                );
                                final selected = await showTimePicker(
                                  context: context,
                                  initialTime: initialTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: AppColors.primaryAccent,
                                          onPrimary: Colors.white,
                                          onSurface: AppColors.textPrimary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (selected != null) {
                                  final updated = _settings!.copyWith(
                                    quietHoursEndMinutes: _timeToMinutes(
                                      selected,
                                    ),
                                  );
                                  _saveSettings(updated);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selesai',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatMinutes(
                                        _settings!.quietHoursEndMinutes,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Card 5: Emergency Disable
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade100, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Colors.red.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Darurat (Emergency)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hentikan seluruh pemantauan dan reset status secara paksa jika terjadi masalah.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await NativeMonitoringService().stopService();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Layanan pemantauan telah dihentikan.',
                                ),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Hentikan Layanan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
      if (candidate.toLowerCase() != 'com' &&
          candidate.toLowerCase() != 'android') {
        return candidate[0].toUpperCase() + candidate.substring(1);
      }
    }
    final label = parts.last;
    return label[0].toUpperCase() + label.substring(1);
  }

  Widget _buildSmallAppIcon(String packageName) {
    final base64Icon = _appIconsMap[packageName];
    if (base64Icon != null && base64Icon.isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            base64Decode(base64Icon),
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
        );
      } catch (e) {
        // fallback
      }
    }
    final cleanName = _getCleanAppName(packageName);
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: AppColors.primaryAccent,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          cleanName.isNotEmpty ? cleanName[0].toUpperCase() : 'A',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
