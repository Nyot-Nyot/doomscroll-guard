import 'package:hive_flutter/hive_flutter.dart';

import '../../shared/models/daily_usage.dart';
import '../../shared/models/permission_state.dart';
import '../../shared/models/settings.dart';
import '../../shared/models/usage_session.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() => _instance;

  LocalStorageService._internal();

  static const String _settingsBoxName = 'settings';
  static const String _permissionsBoxName = 'permissions';
  static const String _dailyUsageBoxName = 'daily_usage';
  static const String _sessionBoxName = 'usage_sessions';
  static const String _appStateBoxName = 'app_state';

  static const String _settingsKey = 'current_settings';
  static const String _permissionKey = 'permission_state';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  Future<void> init() async {
    await Hive.initFlutter();

    _registerAdapterIfNeeded(SettingsAdapter());
    _registerAdapterIfNeeded(PermissionStateAdapter());
    _registerAdapterIfNeeded(DailyUsageAdapter());
    _registerAdapterIfNeeded(UsageSessionAdapter());

    await Future.wait([
      Hive.openBox<Settings>(_settingsBoxName),
      Hive.openBox<PermissionState>(_permissionsBoxName),
      Hive.openBox<DailyUsage>(_dailyUsageBoxName),
      Hive.openBox<UsageSession>(_sessionBoxName),
      Hive.openBox<dynamic>(_appStateBoxName),
    ]);
  }

  void _registerAdapterIfNeeded(TypeAdapter adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  Box<Settings> get _settingsBox => Hive.box<Settings>(_settingsBoxName);
  Box<PermissionState> get _permissionsBox =>
      Hive.box<PermissionState>(_permissionsBoxName);
  Box<DailyUsage> get _dailyUsageBox =>
      Hive.box<DailyUsage>(_dailyUsageBoxName);
  Box<UsageSession> get _sessionBox => Hive.box<UsageSession>(_sessionBoxName);
  Box<dynamic> get _appStateBox => Hive.box<dynamic>(_appStateBoxName);

  Settings? getSettings() => _settingsBox.get(_settingsKey);

  Future<void> saveSettings(Settings settings) async {
    await _settingsBox.put(_settingsKey, settings);
  }

  PermissionState? getPermissionState() => _permissionsBox.get(_permissionKey);

  Future<void> savePermissionState(PermissionState state) async {
    await _permissionsBox.put(_permissionKey, state);
  }

  bool isOnboardingCompleted() {
    return _appStateBox.get(_onboardingCompletedKey, defaultValue: false) == true;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _appStateBox.put(_onboardingCompletedKey, value);
  }

  List<DailyUsage> getAllDailyUsage() => _dailyUsageBox.values.toList();

  Future<void> saveDailyUsage(String key, DailyUsage usage) async {
    await _dailyUsageBox.put(key, usage);
  }

  Future<void> saveTodayUsage(DailyUsage usage) async {
    await saveDailyUsage(todayKey(), usage);
  }

  Future<void> addUsageSession(String key, UsageSession session) async {
    await _sessionBox.put(key, session);
  }

  Future<void> addUsageSessionAuto(UsageSession session) async {
    await addUsageSession(
      createSessionKey(session.startTime, session.packageName),
      session,
    );
  }

  Future<void> seedIfEmpty() async {
    if (_settingsBox.isEmpty) {
      await saveSettings(
        Settings(
          targetApps: const [
            'com.instagram.android',
            'com.zhiliaoapp.musically',
          ],
          thresholdMinutes: 20,
          monitoringEnabled: true,
          whitelistApps: const [],
          quietHoursStartMinutes: -1,
          quietHoursEndMinutes: -1,
        ),
      );
    }

    if (_permissionsBox.isEmpty) {
      await savePermissionState(PermissionState.empty());
    }

    if (!_appStateBox.containsKey(_onboardingCompletedKey)) {
      await setOnboardingCompleted(false);
    }

    if (_dailyUsageBox.isEmpty) {
      await saveTodayUsage(
        DailyUsage(
          date: DateTime.now(),
          usageSecondsByApp: const {
            'com.instagram.android': 120,
            'com.zhiliaoapp.musically': 90,
          },
          warningCount: 1,
        ),
      );
    }
  }

  String todayKey() {
    return dailyKeyForDate(DateTime.now());
  }

  String dailyKeyForDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String createSessionKey(DateTime startTime, String packageName) {
    return "${startTime.millisecondsSinceEpoch}_$packageName";
  }
}
