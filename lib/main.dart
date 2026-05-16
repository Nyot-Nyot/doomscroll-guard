import 'package:doomscrolling_guard/core/services/local_storage_service.dart';
import 'package:doomscrolling_guard/core/services/native_bridge.dart';
import 'package:doomscrolling_guard/shared/models/permission_state.dart';
import 'package:doomscrolling_guard/shared/models/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService().init();
  if (kDebugMode) {
    await LocalStorageService().seedIfEmpty();
  }

  runApp(const MyApp());
}

class AppLaunchState {
  AppLaunchState({
    required this.onboardingCompleted,
    required this.permissionState,
    required this.settings,
  });

  final bool onboardingCompleted;
  final PermissionState permissionState;
  final Settings settings;

  AppLaunchState copyWith({
    bool? onboardingCompleted,
    PermissionState? permissionState,
    Settings? settings,
  }) {
    return AppLaunchState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      permissionState: permissionState ?? this.permissionState,
      settings: settings ?? this.settings,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.localStorageService,
    this.nativeBridge,
    this.initialState,
  });

  final LocalStorageService? localStorageService;
  final NativeBridge? nativeBridge;
  final AppLaunchState? initialState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doomscroll Guard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AppRoot(
        localStorageService: localStorageService ?? LocalStorageService(),
        nativeBridge: nativeBridge ?? NativeBridge(),
        initialState: initialState,
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.localStorageService,
    required this.nativeBridge,
    this.initialState,
  });

  final LocalStorageService localStorageService;
  final NativeBridge nativeBridge;
  final AppLaunchState? initialState;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  AppLaunchState? _state;
  bool _isLoading = true;
  bool _isMonitoringActive = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    if (widget.initialState != null) {
      setState(() {
        _state = widget.initialState;
        _isLoading = false;
      });
      return;
    }

    final savedPermissions =
        widget.localStorageService.getPermissionState() ?? PermissionState.empty();
    final nativePermissions = await widget.nativeBridge.getPermissionState();
    final permissionState = nativePermissions;

    if (!_isSamePermissionState(savedPermissions, permissionState)) {
      await widget.localStorageService.savePermissionState(permissionState);
    }

    final settings = widget.localStorageService.getSettings() ?? _defaultSettings();
    final onboardingCompleted = widget.localStorageService.isOnboardingCompleted();

    setState(() {
      _state = AppLaunchState(
        onboardingCompleted: onboardingCompleted,
        permissionState: permissionState,
        settings: settings,
      );
      _isLoading = false;
    });
  }

  Future<void> _completeOnboarding() async {
    await widget.localStorageService.setOnboardingCompleted(true);
    setState(() {
      _state = _state?.copyWith(onboardingCompleted: true);
    });
  }

  Future<void> _refreshPermissionState() async {
    final permissionState = await widget.nativeBridge.getPermissionState();
    await _updatePermissionState(permissionState);
  }

  Future<void> _requestAccessibilityPermission() async {
    final permissionState =
        await widget.nativeBridge.requestAccessibilityPermission();
    await _updatePermissionState(permissionState);
  }

  Future<void> _requestUsageAccessPermission() async {
    final permissionState =
        await widget.nativeBridge.requestUsageAccessPermission();
    await _updatePermissionState(permissionState);
  }

  Future<void> _requestOverlayPermission() async {
    final permissionState = await widget.nativeBridge.requestOverlayPermission();
    await _updatePermissionState(permissionState);
  }

  Future<void> _requestBatteryOptimizationPermission() async {
    final permissionState =
        await widget.nativeBridge.requestBatteryOptimizationPermission();
    await _updatePermissionState(permissionState);
  }

  Future<void> _startMonitoring() async {
    final currentState = _state;
    if (currentState == null) {
      return;
    }

    if (!currentState.permissionState.isComplete) {
      _showMessage(
        'Lengkapi semua permission sebelum memulai monitoring.',
      );
      return;
    }

    if (!currentState.settings.monitoringEnabled) {
      _showMessage('Monitoring dinonaktifkan di pengaturan.');
      return;
    }

    final started = await widget.nativeBridge.startService(
      permissionState: currentState.permissionState,
    );

    setState(() {
      _isMonitoringActive = started;
    });

    _showMessage(started ? 'Monitoring aktif.' : 'Gagal mengaktifkan monitoring.');
  }

  Future<void> _updatePermissionState(PermissionState permissionState) async {
    await widget.localStorageService.savePermissionState(permissionState);

    setState(() {
      _state = _state?.copyWith(permissionState: permissionState);
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_state!.onboardingCompleted) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    return PermissionSetupScreen(
      permissionState: _state!.permissionState,
      monitoringEnabled: _state!.settings.monitoringEnabled,
      isMonitoringActive: _isMonitoringActive,
      onRefresh: _refreshPermissionState,
      onRequestAccessibility: _requestAccessibilityPermission,
      onRequestUsageAccess: _requestUsageAccessPermission,
      onRequestOverlay: _requestOverlayPermission,
      onRequestBatteryOptimization: _requestBatteryOptimizationPermission,
      onStartMonitoring: _startMonitoring,
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<_OnboardingStep> _steps = <_OnboardingStep>[
    _OnboardingStep(
      title: 'Selamat datang di Doomscroll Guard',
      description:
          'Aplikasi ini membantu memantau penggunaan aplikasi doomscrolling dan memberi pengingat ringan.',
    ),
    _OnboardingStep(
      title: 'Bagaimana cara kerjanya?',
      description:
          'Kami memonitor aplikasi foreground, menghitung durasi penggunaan, lalu memberi intervensi saat batas tercapai.',
    ),
    _OnboardingStep(
      title: 'Selesaikan setup permission',
      description:
          'Berikutnya, izinkan Accessibility, Usage Access, Overlay, dan Battery Optimization agar monitoring dapat berjalan.',
    ),
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentIndex];
    final isLast = _currentIndex == _steps.length - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Langkah ${_currentIndex + 1} dari ${_steps.length}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            Text(step.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(step.description, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Row(
              children: [
                if (_currentIndex > 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex -= 1;
                      });
                    },
                    child: const Text('Kembali'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    if (isLast) {
                      await widget.onComplete();
                      return;
                    }

                    setState(() {
                      _currentIndex += 1;
                    });
                  },
                  child: Text(isLast ? 'Lanjut ke Setup' : 'Berikutnya'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PermissionSetupScreen extends StatelessWidget {
  const PermissionSetupScreen({
    super.key,
    required this.permissionState,
    required this.monitoringEnabled,
    required this.isMonitoringActive,
    required this.onRefresh,
    required this.onRequestAccessibility,
    required this.onRequestUsageAccess,
    required this.onRequestOverlay,
    required this.onRequestBatteryOptimization,
    required this.onStartMonitoring,
  });

  final PermissionState permissionState;
  final bool monitoringEnabled;
  final bool isMonitoringActive;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRequestAccessibility;
  final Future<void> Function() onRequestUsageAccess;
  final Future<void> Function() onRequestOverlay;
  final Future<void> Function() onRequestBatteryOptimization;
  final Future<void> Function() onStartMonitoring;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permission Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Checklist Permission',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monitoring hanya aktif jika semua permission sudah lengkap.',
          ),
          const SizedBox(height: 16),
          _PermissionItem(
            title: 'Accessibility',
            description: 'Diperlukan untuk deteksi aplikasi foreground.',
            granted: permissionState.accessibilityGranted,
            onRequest: onRequestAccessibility,
          ),
          _PermissionItem(
            title: 'Usage Access',
            description: 'Diperlukan untuk membaca statistik penggunaan.',
            granted: permissionState.usageAccessGranted,
            onRequest: onRequestUsageAccess,
          ),
          _PermissionItem(
            title: 'Overlay',
            description: 'Diperlukan untuk menampilkan popup intervensi.',
            granted: permissionState.overlayGranted,
            onRequest: onRequestOverlay,
          ),
          _PermissionItem(
            title: 'Battery Optimization',
            description:
                'Agar service tidak mudah dihentikan oleh sistem.',
            granted: permissionState.batteryOptimizationIgnored,
            onRequest: onRequestBatteryOptimization,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRefresh,
            child: const Text('Cek Ulang Status Permission'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                permissionState.isComplete && monitoringEnabled
                ? onStartMonitoring
                : null,
            child: const Text('Mulai Monitoring'),
          ),
          const SizedBox(height: 8),
          Text(
            isMonitoringActive
                ? 'Status: Monitoring Aktif'
                : 'Status: Monitoring Belum Aktif',
          ),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({
    required this.title,
    required this.description,
    required this.granted,
    required this.onRequest,
  });

  final String title;
  final String description;
  final bool granted;
  final Future<void> Function() onRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          granted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: granted ? Colors.green : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: TextButton(
          onPressed: onRequest,
          child: Text(granted ? 'Sudah' : 'Izinkan'),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({required this.title, required this.description});

  final String title;
  final String description;
}

Settings _defaultSettings() {
  return Settings(
    targetApps: const <String>[],
    thresholdMinutes: 20,
    monitoringEnabled: true,
    whitelistApps: const <String>[],
    quietHoursStartMinutes: -1,
    quietHoursEndMinutes: -1,
  );
}

bool _isSamePermissionState(PermissionState a, PermissionState b) {
  return a.accessibilityGranted == b.accessibilityGranted &&
      a.usageAccessGranted == b.usageAccessGranted &&
      a.overlayGranted == b.overlayGranted &&
      a.batteryOptimizationIgnored == b.batteryOptimizationIgnored;
}
