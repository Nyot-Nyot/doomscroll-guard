import 'package:flutter/material.dart';

import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/native_monitoring_service.dart';
import '../../../../shared/models/settings.dart';
import '../../../../shared/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
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
                        const Column(
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
                            final parts = pkg.split('.');
                            final label = parts.last.toUpperCase();

                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
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
}
