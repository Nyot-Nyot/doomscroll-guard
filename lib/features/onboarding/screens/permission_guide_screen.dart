import 'package:doomscrolling_guard/core/services/local_storage_service.dart';
import 'package:doomscrolling_guard/core/services/native_permission_service.dart';
import 'package:doomscrolling_guard/core/themes/app_colors.dart';
import 'package:doomscrolling_guard/features/onboarding/screens/app_picker_screen.dart';
import 'package:doomscrolling_guard/shared/models/permission_state.dart';
import 'package:flutter/material.dart';

class PermissionGuideScreen extends StatefulWidget {
  const PermissionGuideScreen({super.key});

  @override
  State<PermissionGuideScreen> createState() => _PermissionGuideScreenState();
}

class _PermissionGuideScreenState extends State<PermissionGuideScreen>
    with WidgetsBindingObserver {
  final NativePermissionService _permissionService = NativePermissionService();

  final Map<String, bool> _permissionStatus = {
    'accessibility': false,
    'usage': false,
    'overlay': false,
    'battery': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final status = await _permissionService.checkPermissions();
    if (mounted) {
      setState(() {
        _permissionStatus.addAll(status);
      });

      final state = PermissionState(
        accessibilityGranted: status['accessibility'] ?? false,
        usageAccessGranted: status['usage'] ?? false,
        overlayGranted: status['overlay'] ?? false,
        batteryOptimizationIgnored: status['battery'] ?? false,
      );
      await LocalStorageService().savePermissionState(state);
    }
  }

  Future<void> _requestPermission(String key) async {
    switch (key) {
      case 'accessibility':
        await _permissionService.requestAccessibility();
        break;
      case 'usage':
        await _permissionService.requestUsageAccess();
        break;
      case 'overlay':
        await _permissionService.requestOverlay();
        break;
      case 'battery':
        await _permissionService.requestBatteryOptimization();
        break;
    }
    // We don't await Settings screens, user comes back -> didChangeAppLifecycleState triggers check
  }

  bool get _allGranted {
    return _permissionStatus.values.every((v) => v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Izin'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengaturan Izin',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Langkah ini membantu Doomscroll Guard berjalan lancar tanpa mengganggu aktivitas Anda. Semua data tetap tersimpan di perangkat.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Silakan beri izin satu per satu. Setelah semua langkah selesai, Anda bisa memilih aplikasi yang ingin dipantau.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionItem(
                      icon: Icons.accessibility_new_rounded,
                      title: 'Akses Accessibility',
                      description:
                          'Izinkan untuk mendeteksi saat aplikasi target dibuka dan menampilkan pengingat tepat waktu.',
                      key: 'accessibility',
                    ),
                    _buildPermissionItem(
                      icon: Icons.analytics_outlined,
                      title: 'Akses Penggunaan',
                      description:
                          'Izinkan agar Doomscroll Guard dapat membaca durasi penggunaan layar dan membuat ringkasan yang akurat.',
                      key: 'usage',
                    ),
                    _buildPermissionItem(
                      icon: Icons.layers_outlined,
                      title: 'Tampilkan di atas aplikasi lain',
                      description:
                          'Izinkan agar pengingat ringan dapat muncul saat Anda sedang scrolling.',
                      key: 'overlay',
                    ),
                    _buildPermissionItem(
                      icon: Icons.battery_charging_full_rounded,
                      title: 'Optimasi Baterai',
                      description:
                          'Abaikan optimasi baterai supaya layanan monitoring tetap berjalan di latar belakang.',
                      key: 'battery',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allGranted
                      ? () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const AppPickerScreen(),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required String key,
  }) {
    final granted = _permissionStatus[key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted ? AppColors.primaryAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: granted ? AppColors.primaryAccent : AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: granted ? Colors.white : AppColors.primaryAccent,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(description),
        ),
        trailing: granted
            ? const Icon(Icons.check_circle, color: AppColors.primaryAccent)
            : TextButton(
                onPressed: () => _requestPermission(key),
                child: const Text('Izinkan'),
              ),
      ),
    );
  }
}
