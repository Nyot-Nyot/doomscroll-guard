import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativePermissionService {
  static const MethodChannel _channel = MethodChannel('doomscroll_guard/channel');

  Future<Map<String, bool>> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('checkPermissions');
      if (result != null) {
        return result.map((key, value) => MapEntry(key.toString(), value as bool));
      }
    } catch (e) {
      debugPrint("checkPermissions error: $e");
    }
    return {
      'accessibility': false,
      'usage': false,
      'overlay': false,
      'battery': false,
    };
  }

  Future<void> requestAccessibility() async {
    try {
      await _channel.invokeMethod('requestAccessibility');
    } catch (e) {
      debugPrint("requestAccessibility error: $e");
    }
  }

  Future<void> requestUsageAccess() async {
    try {
      await _channel.invokeMethod('requestUsageAccess');
    } catch (e) {
      debugPrint("requestUsageAccess error: $e");
    }
  }

  Future<void> requestOverlay() async {
    try {
      await _channel.invokeMethod('requestOverlay');
    } catch (e) {
      debugPrint("requestOverlay error: $e");
    }
  }

  Future<void> requestBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestBatteryOptimization');
    } catch (e) {
      debugPrint("requestBatteryOptimization error: $e");
    }
  }
}
