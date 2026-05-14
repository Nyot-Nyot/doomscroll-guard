import 'package:hive/hive.dart';

class DailyUsage {
  DailyUsage({
    required this.date,
    required this.usageSecondsByApp,
    required this.warningCount,
  });

  final DateTime date;
  final Map<String, int> usageSecondsByApp;
  final int warningCount;
}

class DailyUsageAdapter extends TypeAdapter<DailyUsage> {
  @override
  final int typeId = 3;

  @override
  DailyUsage read(BinaryReader reader) {
    final dateMillis = reader.readInt();
    final usageSecondsByApp =
        Map<String, int>.from(reader.readMap());
    final warningCount = reader.readInt();

    return DailyUsage(
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      usageSecondsByApp: usageSecondsByApp,
      warningCount: warningCount,
    );
  }

  @override
  void write(BinaryWriter writer, DailyUsage obj) {
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeMap(obj.usageSecondsByApp);
    writer.writeInt(obj.warningCount);
  }
}
