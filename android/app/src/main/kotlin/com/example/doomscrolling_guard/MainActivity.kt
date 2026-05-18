package com.example.doomscrolling_guard

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> result.success(getPermissionsStatus())
                "requestAccessibility" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(true)
                }
                "requestUsageAccess" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "requestOverlay" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
                    } catch (e: Exception) {
                        startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION))
                    }
                    result.success(true)
                }
                "requestBatteryOptimization" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
                    } catch (e: Exception) {
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                    }
                    result.success(true)
                }
                "startService" -> {
                    val targetApps = call.argument<List<String>>("targetApps")
                    val thresholdMinutes = call.argument<Int>("thresholdMinutes") ?: 20
                    if (targetApps != null) {
                        val prefs = context.getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
                        prefs.edit()
                            .putStringSet("targetApps", targetApps.toSet())
                            .putInt("thresholdMinutes", thresholdMinutes)
                            .apply()
                    }

                    val serviceIntent = Intent(context, MonitoringService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                    result.success(true)
                }
                "stopService" -> {
                    val serviceIntent = Intent(context, MonitoringService::class.java)
                    context.stopService(serviceIntent)
                    result.success(true)
                }
                "getMonitoringState" -> {
                    result.success(mapOf(
                        "isRunning" to MonitoringService.isRunning,
                        "warningCount" to SessionManager.getWarningCountToday()
                    ))
                }
                "getUsageStats" -> {
                    val prefs = context.getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
                    val targetApps = prefs.getStringSet("targetApps", emptySet()) ?: emptySet()
                    val statsMap = mutableMapOf<String, Long>()
                    
                    for (app in targetApps) {
                        statsMap[app] = SessionManager.getRealtimeDailyUsage(context, app)
                    }
                    result.success(statsMap)
                }
                "getInstalledApps" -> result.success(getInstalledApps(context))
                else -> result.notImplemented()
            }
        }
    }

    private fun getPermissionsStatus(): Map<String, Boolean> {
        return mapOf(
            "accessibility" to isAccessibilityServiceEnabled(),
            "usage" to hasUsageStatsPermission(),
            "overlay" to Settings.canDrawOverlays(this),
            "battery" to isIgnoringBatteryOptimizations()
        )
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        var accessibilityEnabled = 0
        val service = packageName + "/" + "com.example.doomscrolling_guard.MonitoringAccessibilityService"
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                applicationContext.contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
        } catch (e: Settings.SettingNotFoundException) {
            return false
        }
        
        if (accessibilityEnabled == 1) {
            val settingValue = Settings.Secure.getString(
                applicationContext.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            if (settingValue != null) {
                val splitter = TextUtils.SimpleStringSplitter(':')
                splitter.setString(settingValue)
                while (splitter.hasNext()) {
                    if (splitter.next().equals(service, ignoreCase = true)) {
                        return true
                    }
                }
            }
        }
        return false
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(), packageName
        )
        return if (mode == AppOpsManager.MODE_DEFAULT) {
            checkCallingOrSelfPermission(android.Manifest.permission.PACKAGE_USAGE_STATS) == PackageManager.PERMISSION_GRANTED
        } else {
            mode == AppOpsManager.MODE_ALLOWED
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun getInstalledApps(context: Context): List<Map<String, String>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }
        
        val resolveInfos = pm.queryIntentActivities(intent, 0)
        val appList = mutableListOf<Map<String, String>>()
        val uniquePackages = mutableSetOf<String>()

        for (resolveInfo in resolveInfos) {
            val packageName = resolveInfo.activityInfo.packageName
            if (!uniquePackages.contains(packageName) && packageName != context.packageName) {
                val appName = resolveInfo.loadLabel(pm).toString()
                appList.add(mapOf("packageName" to packageName, "appName" to appName))
                uniquePackages.add(packageName)
            }
        }
        
        // Sort alphabetically by app name
        return appList.sortedBy { it["appName"]?.lowercase() }
    }

    private companion object {
        const val CHANNEL = "doomscroll_guard/channel"
    }
}
