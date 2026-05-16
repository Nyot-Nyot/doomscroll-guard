import 'package:flutter/material.dart';
import 'package:doomscrolling_guard/core/services/installed_apps_service.dart';
import 'package:doomscrolling_guard/core/services/local_storage_service.dart';
import 'package:doomscrolling_guard/core/themes/app_colors.dart';
import 'package:doomscrolling_guard/shared/models/settings.dart';
import 'package:doomscrolling_guard/features/dashboard/screens/dashboard_screen.dart';

class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({super.key});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  final InstalledAppsService _appsService = InstalledAppsService();
  bool _isLoading = true;
  List<Map<String, String>> _apps = [];
  final Set<String> _selectedPackages = {};

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final settings = LocalStorageService().getSettings();
    if (settings != null) {
      _selectedPackages.addAll(settings.targetApps);
    }
    
    final apps = await _appsService.getInstalledApps();
    
    if (mounted) {
      setState(() {
        _apps = apps;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    final settings = LocalStorageService().getSettings();
    if (settings != null) {
      await LocalStorageService().saveSettings(
        settings.copyWith(targetApps: _selectedPackages.toList()),
      );
    } else {
      await LocalStorageService().saveSettings(
        Settings(
          targetApps: _selectedPackages.toList(),
          thresholdMinutes: 20,
          monitoringEnabled: true,
          whitelistApps: [],
          quietHoursStartMinutes: 0,
          quietHoursEndMinutes: 0,
        ),
      );
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps to Monitor'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    'Choose the apps you find yourself scrolling endlessly on. We suggest social media apps like Instagram, TikTok, or Twitter.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _apps.length,
                    itemBuilder: (context, index) {
                      final app = _apps[index];
                      final packageName = app['packageName'] ?? '';
                      final isSelected = _selectedPackages.contains(packageName);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedPackages.add(packageName);
                            } else {
                              _selectedPackages.remove(packageName);
                            }
                          });
                        },
                        title: Text(
                          app['appName'] ?? packageName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                        ),
                        subtitle: Text(
                          packageName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary.withOpacity(0.7),
                              ),
                        ),
                        activeColor: AppColors.primaryAccent,
                        checkColor: Colors.white,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedPackages.isEmpty ? null : _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('Done (${_selectedPackages.length} selected)'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
