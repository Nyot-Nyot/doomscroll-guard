package com.example.doomscrolling_guard

import android.content.Context
import android.util.Log

object ThresholdEngine {
    fun checkUsage(context: Context, packageName: String): Boolean {
        if (MonitoringService.isPaused) {
            Log.i("DoomscrollGuard", "ThresholdEngine: Monitoring is paused, skipping checks.")
            return false
        }
        if (SessionManager.isSnoozed()) {
            Log.i("DoomscrollGuard", "ThresholdEngine: Monitoring is snoozed, skipping checks.")
            return false
        }
        if (SessionManager.isGraceActive()) {
            Log.i("DoomscrollGuard", "ThresholdEngine: Grace period is active, skipping checks.")
            return false
        }

        val prefs = context.getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
        
        // 1. Whitelist Check
        val whitelistApps = prefs.getStringSet("whitelistApps", emptySet()) ?: emptySet()
        if (whitelistApps.contains(packageName)) {
            Log.i("DoomscrollGuard", "ThresholdEngine: App $packageName is whitelisted, skipping intervention.")
            return false
        }

        // 2. Quiet Hours Check
        val quietHoursStart = prefs.getInt("quietHoursStart", -1)
        val quietHoursEnd = prefs.getInt("quietHoursEnd", -1)
        if (quietHoursStart != -1 && quietHoursEnd != -1) {
            val calendar = java.util.Calendar.getInstance()
            val currentMinutes = calendar.get(java.util.Calendar.HOUR_OF_DAY) * 60 + calendar.get(java.util.Calendar.MINUTE)
            val isQuietHoursActive = if (quietHoursStart <= quietHoursEnd) {
                currentMinutes in quietHoursStart..quietHoursEnd
            } else {
                currentMinutes >= quietHoursStart || currentMinutes <= quietHoursEnd
            }
            if (isQuietHoursActive) {
                Log.i("DoomscrollGuard", "ThresholdEngine: Quiet hours active, skipping intervention.")
                return false
            }
        }

        val thresholdMinutes = prefs.getInt("thresholdMinutes", 20)
        
        // 0 thresholdMinutes represents the 10-second testing mode
        val limitMs = if (thresholdMinutes == 0) {
            10 * 1000L
        } else {
            thresholdMinutes * 60 * 1000L
        }
        
        val sessionDurationMs = SessionManager.getCurrentSessionDuration(packageName)
        
        if (sessionDurationMs >= limitMs) {
            Log.w("DoomscrollGuard", "THRESHOLD REACHED FOR $packageName: Session duration $sessionDurationMs ms >= $limitMs ms")
            OverlayManager.showIntervention(context, packageName)
            return true
        } else {
            Log.i("DoomscrollGuard", "Session duration for $packageName is $sessionDurationMs ms (Limit: $limitMs ms)")
            return false
        }
    }
}
