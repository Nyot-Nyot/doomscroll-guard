import 'package:hive/hive.dart';

class UsageSession {
  UsageSession({
    required this.packageName,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.thresholdReached,
  });

  final String packageName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final bool thresholdReached;
}

class UsageSessionAdapter extends TypeAdapter<UsageSession> {
  @override
  final int typeId = 2;

  @override
  UsageSession read(BinaryReader reader) {
    final packageName = reader.readString();
    final startMillis = reader.readInt();
    final hasEnd = reader.readBool();
    final endMillis = hasEnd ? reader.readInt() : null;
    final durationSeconds = reader.readInt();
    final thresholdReached = reader.readBool();

    return UsageSession(
      packageName: packageName,
      startTime: DateTime.fromMillisecondsSinceEpoch(startMillis),
      endTime: endMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(endMillis),
      durationSeconds: durationSeconds,
      thresholdReached: thresholdReached,
    );
  }

  @override
  void write(BinaryWriter writer, UsageSession obj) {
    writer.writeString(obj.packageName);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeBool(obj.endTime != null);
    if (obj.endTime != null) {
      writer.writeInt(obj.endTime!.millisecondsSinceEpoch);
    }
    writer.writeInt(obj.durationSeconds);
    writer.writeBool(obj.thresholdReached);
  }
}
