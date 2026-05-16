import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativeMonitoringService {
  static const MethodChannel _channel = MethodChannel('doomscroll_guard/channel');

  Future<void> startService(List<String> targetApps, int thresholdMinutes) async {
    try {
      await _channel.invokeMethod('startService', {'targetApps': targetApps, 'thresholdMinutes': thresholdMinutes});
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

  Future<Map<String, int>> getUsageStats() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getUsageStats');
      if (result == null) return {};
      
      final Map<String, int> stats = {};
      for (final key in result.keys) {
         stats[key.toString()] = (result[key] is int) 
            ? result[key] 
            : (int.tryParse(result[key].toString()) ?? 0);
      }
      return stats;
    } catch (e) {
      debugPrint("Error getting usage stats: $e");
      return {};
    }
  }
}
