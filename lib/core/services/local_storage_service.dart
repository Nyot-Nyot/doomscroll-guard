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

  static const String _settingsKey = 'current_settings';
  static const String _permissionKey = 'permission_state';

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

  Settings? getSettings() => _settingsBox.get(_settingsKey);

  Future<void> saveSettings(Settings settings) async {
    await _settingsBox.put(_settingsKey, settings);
  }

  PermissionState? getPermissionState() => _permissionsBox.get(_permissionKey);

  Future<void> savePermissionState(PermissionState state) async {
    await _permissionsBox.put(_permissionKey, state);
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
      await savePermissionState(
        PermissionState(
          accessibilityGranted: false,
          usageAccessGranted: false,
          overlayGranted: false,
          batteryOptimizationIgnored: false,
        ),
      );
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
