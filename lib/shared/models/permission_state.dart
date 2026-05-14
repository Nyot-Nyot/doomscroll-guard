import 'package:hive/hive.dart';

class PermissionState {
  PermissionState({
    required this.accessibilityGranted,
    required this.usageAccessGranted,
    required this.overlayGranted,
    required this.batteryOptimizationIgnored,
  });

  final bool accessibilityGranted;
  final bool usageAccessGranted;
  final bool overlayGranted;
  final bool batteryOptimizationIgnored;
}

class PermissionStateAdapter extends TypeAdapter<PermissionState> {
  @override
  final int typeId = 4;

  @override
  PermissionState read(BinaryReader reader) {
    final accessibilityGranted = reader.readBool();
    final usageAccessGranted = reader.readBool();
    final overlayGranted = reader.readBool();
    final batteryOptimizationIgnored = reader.readBool();

    return PermissionState(
      accessibilityGranted: accessibilityGranted,
      usageAccessGranted: usageAccessGranted,
      overlayGranted: overlayGranted,
      batteryOptimizationIgnored: batteryOptimizationIgnored,
    );
  }

  @override
  void write(BinaryWriter writer, PermissionState obj) {
    writer.writeBool(obj.accessibilityGranted);
    writer.writeBool(obj.usageAccessGranted);
    writer.writeBool(obj.overlayGranted);
    writer.writeBool(obj.batteryOptimizationIgnored);
  }
}
