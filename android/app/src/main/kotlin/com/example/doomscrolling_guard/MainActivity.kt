package com.example.doomscrolling_guard

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> result.success(areAllPermissionsGranted())
                "stopService" -> result.success(false)
                "getMonitoringState" -> result.success(mapOf("isRunning" to false))
                "getUsageStats" -> result.success(emptyList<Any>())
                "getPermissionState" -> result.success(currentPermissionState())
                "requestAccessibilityPermission" -> {
                    openSettings(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                    result.success(currentPermissionState())
                }

                "requestUsageAccessPermission" -> {
                    openSettings(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(currentPermissionState())
                }

                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        openSettings(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName"),
                            ),
                        )
                    }
                    result.success(currentPermissionState())
                }

                "requestBatteryOptimizationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        openSettings(
                            Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName"),
                            ),
                        )
                    }
                    result.success(currentPermissionState())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun openSettings(intent: Intent) {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun currentPermissionState(): Map<String, Boolean> {
        return mapOf(
            "accessibilityGranted" to isAccessibilityServiceEnabled(),
            "usageAccessGranted" to hasUsageAccessPermission(),
            "overlayGranted" to hasOverlayPermission(),
            "batteryOptimizationIgnored" to isIgnoringBatteryOptimization(),
        )
    }

    private fun areAllPermissionsGranted(): Boolean {
        val state = currentPermissionState()
        return state.values.all { it }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        return Settings.Secure.getInt(
            contentResolver,
            Settings.Secure.ACCESSIBILITY_ENABLED,
            0,
        ) == 1
    }

    private fun hasUsageAccessPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    applicationInfo.uid,
                    packageName,
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    applicationInfo.uid,
                    packageName,
                )
            }

        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun isIgnoringBatteryOptimization(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    private companion object {
        const val CHANNEL = "doomscroll_guard/channel"
    }
}
