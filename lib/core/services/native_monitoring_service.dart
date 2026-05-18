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

  Future<void> updateServiceConfig(List<String> targetApps, int thresholdMinutes) async {
    try {
      await _channel.invokeMethod('updateServiceConfig', {'targetApps': targetApps, 'thresholdMinutes': thresholdMinutes});
    } catch (e) {
      debugPrint("Error updating service config: $e");
    }
  }

  Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (e) {
      debugPrint("Error stopping service: $e");
    }
  }
  
  Future<Map<String, dynamic>> getMonitoringState() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('getMonitoringState');
      if (result == null) return {'isRunning': false, 'warningCount': 0};
      return {
        'isRunning': result['isRunning'] ?? false,
        'warningCount': result['warningCount'] ?? 0,
      };
    } catch (e) {
      debugPrint("Error getting state: $e");
      return {'isRunning': false, 'warningCount': 0};
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

  Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getInstalledApps');
      if (result == null) return [];
      return result.map((item) {
        final Map<dynamic, dynamic> map = item as Map<dynamic, dynamic>;
        return {
          'packageName': map['packageName']?.toString() ?? '',
          'appName': map['appName']?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint("Error getting installed apps: $e");
      return [];
    }
  }
}
