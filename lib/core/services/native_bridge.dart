import 'package:flutter/services.dart';

class NativeBridge {
  static const MethodChannel _channel = MethodChannel(
    'doomscroll_guard/channel',
  );

  Future<bool> startService() async {
    final result = await _channel.invokeMethod<bool>('startService');
    return result ?? false;
  }

  Future<bool> stopService() async {
    final result = await _channel.invokeMethod<bool>('stopService');
    return result ?? false;
  }

  Future<Map<String, dynamic>> getMonitoringState() async {
    final result = await _channel.invokeMethod<Map>('getMonitoringState');
    return Map<String, dynamic>.from(result ?? {});
  }

  Future<List<dynamic>> getUsageStats() async {
    final result = await _channel.invokeMethod<List>('getUsageStats');
    return result ?? [];
  }
}
