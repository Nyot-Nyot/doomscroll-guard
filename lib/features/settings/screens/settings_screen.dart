import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/native_monitoring_service.dart';
import '../../../../shared/models/settings.dart';
import '../../../../core/themes/app_colors.dart';
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
        updatedSettings.targetApps,
        updatedSettings.thresholdMinutes,
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
        currentSettings: _settings!,
        onSaved: (selectedApps) {
          final updated = _settings!.copyWith(targetApps: selectedApps);
          _saveSettings(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Pengaturan Batas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sesuaikan batas waktu dan aplikasi yang dipantau agar kebiasaan digital Anda tetap sehat.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
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
                              final updatedMinutes = value ? 0 : _sliderValue.round();
                              _saveSettings(
                                _settings!.copyWith(thresholdMinutes: updatedMinutes),
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
                              inactiveTrackColor: AppColors.surface.withOpacity(0.5),
                              thumbColor: AppColors.primaryAccent,
                              overlayColor: AppColors.primaryAccent.withOpacity(0.12),
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
                                Text('1m', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text('15m', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text('30m', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text('45m', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text('60m', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
