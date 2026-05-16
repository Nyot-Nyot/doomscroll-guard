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

  bool get isComplete =>
      accessibilityGranted &&
      usageAccessGranted &&
      overlayGranted &&
      batteryOptimizationIgnored;

  PermissionState copyWith({
    bool? accessibilityGranted,
    bool? usageAccessGranted,
    bool? overlayGranted,
    bool? batteryOptimizationIgnored,
  }) {
    return PermissionState(
      accessibilityGranted: accessibilityGranted ?? this.accessibilityGranted,
      usageAccessGranted: usageAccessGranted ?? this.usageAccessGranted,
      overlayGranted: overlayGranted ?? this.overlayGranted,
      batteryOptimizationIgnored:
          batteryOptimizationIgnored ?? this.batteryOptimizationIgnored,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'accessibilityGranted': accessibilityGranted,
      'usageAccessGranted': usageAccessGranted,
      'overlayGranted': overlayGranted,
      'batteryOptimizationIgnored': batteryOptimizationIgnored,
    };
  }

  static PermissionState fromMap(Map<dynamic, dynamic>? map) {
    final source = map ?? const <dynamic, dynamic>{};
    return PermissionState(
      accessibilityGranted: source['accessibilityGranted'] == true,
      usageAccessGranted: source['usageAccessGranted'] == true,
      overlayGranted: source['overlayGranted'] == true,
      batteryOptimizationIgnored: source['batteryOptimizationIgnored'] == true,
    );
  }

  static PermissionState empty() {
    return PermissionState(
      accessibilityGranted: false,
      usageAccessGranted: false,
      overlayGranted: false,
      batteryOptimizationIgnored: false,
    );
  }
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
