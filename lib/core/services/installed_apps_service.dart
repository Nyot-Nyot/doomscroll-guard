import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class InstalledAppsService {
  static const MethodChannel _channel = MethodChannel('doomscroll_guard/channel');

  Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getInstalledApps');
      if (result != null) {
        return result.map((e) => Map<String, String>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching installed apps: $e");
    }
    return [];
  }
}
