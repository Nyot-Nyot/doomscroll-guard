import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativeMonitoringService {
  static const MethodChannel _channel = MethodChannel('doomscroll_guard/channel');

  Future<void> startService() async {
    try {
      await _channel.invokeMethod('startService');
    } catch (e) {
      debugPrint("Error starting service: $e");
    }
  }

  Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (e) {
      debugPrint("Error stopping service: $e");
    }
  }
  
  Future<bool> getMonitoringState() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getMonitoringState');
      return result?['isRunning'] ?? false;
    } catch (e) {
      debugPrint("Error getting state: $e");
      return false;
    }
  }
}
