import 'package:hive/hive.dart';

class Settings {
  Settings({
    required this.targetApps,
    required this.thresholdMinutes,
    required this.monitoringEnabled,
    required this.whitelistApps,
    required this.quietHoursStartMinutes,
    required this.quietHoursEndMinutes,
  });

  final List<String> targetApps;
  final int thresholdMinutes;
  final bool monitoringEnabled;
  final List<String> whitelistApps;
  final int quietHoursStartMinutes;
  final int quietHoursEndMinutes;

  Settings copyWith({
    List<String>? targetApps,
    int? thresholdMinutes,
    bool? monitoringEnabled,
    List<String>? whitelistApps,
    int? quietHoursStartMinutes,
    int? quietHoursEndMinutes,
  }) {
    return Settings(
      targetApps: targetApps ?? this.targetApps,
      thresholdMinutes: thresholdMinutes ?? this.thresholdMinutes,
      monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
      whitelistApps: whitelistApps ?? this.whitelistApps,
      quietHoursStartMinutes:
          quietHoursStartMinutes ?? this.quietHoursStartMinutes,
      quietHoursEndMinutes:
          quietHoursEndMinutes ?? this.quietHoursEndMinutes,
    );
  }
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 1;

  @override
  Settings read(BinaryReader reader) {
    final targetApps = reader.readList().cast<String>();
    final thresholdMinutes = reader.readInt();
    final monitoringEnabled = reader.readBool();
    final whitelistApps = reader.readList().cast<String>();
    final quietHoursStartMinutes = reader.readInt();
    final quietHoursEndMinutes = reader.readInt();

    return Settings(
      targetApps: targetApps,
      thresholdMinutes: thresholdMinutes,
      monitoringEnabled: monitoringEnabled,
      whitelistApps: whitelistApps,
      quietHoursStartMinutes: quietHoursStartMinutes,
      quietHoursEndMinutes: quietHoursEndMinutes,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer.writeList(obj.targetApps);
    writer.writeInt(obj.thresholdMinutes);
    writer.writeBool(obj.monitoringEnabled);
    writer.writeList(obj.whitelistApps);
    writer.writeInt(obj.quietHoursStartMinutes);
    writer.writeInt(obj.quietHoursEndMinutes);
  }
}
