import 'package:doomscrolling_guard/shared/models/permission_state.dart';
import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel(
    'doomscroll_guard/channel',
  );

  Future<bool> startService({required PermissionState permissionState}) async {
    if (!permissionState.isComplete) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('startService');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> stopService() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopService');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<Map<String, dynamic>> getMonitoringState() async {
    try {
      final result = await _channel.invokeMethod<Map>('getMonitoringState');
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException {
      return <String, dynamic>{};
    } on MissingPluginException {
      return <String, dynamic>{};
    }
  }

  Future<List<dynamic>> getUsageStats() async {
    try {
      final result = await _channel.invokeMethod<List>('getUsageStats');
      return result ?? [];
    } on PlatformException {
      return <dynamic>[];
    } on MissingPluginException {
      return <dynamic>[];
    }
  }

  Future<PermissionState> getPermissionState() async {
    return _readPermissionState('getPermissionState');
  }

  Future<PermissionState> requestAccessibilityPermission() async {
    return _readPermissionState('requestAccessibilityPermission');
  }

  Future<PermissionState> requestUsageAccessPermission() async {
    return _readPermissionState('requestUsageAccessPermission');
  }

  Future<PermissionState> requestOverlayPermission() async {
    return _readPermissionState('requestOverlayPermission');
  }

  Future<PermissionState> requestBatteryOptimizationPermission() async {
    return _readPermissionState('requestBatteryOptimizationPermission');
  }

  Future<PermissionState> _readPermissionState(String method) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(method);
      return PermissionState.fromMap(result);
    } on PlatformException {
      return PermissionState.empty();
    } on MissingPluginException {
      return PermissionState.empty();
    }
  }
}
