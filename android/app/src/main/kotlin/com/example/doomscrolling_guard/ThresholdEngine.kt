package com.example.doomscrolling_guard

import android.content.Context
import android.util.Log

object ThresholdEngine {
    fun checkUsage(context: Context, packageName: String): Boolean {
        if (SessionManager.isSnoozed()) {
            Log.i("DoomscrollGuard", "ThresholdEngine: Monitoring is snoozed, skipping checks.")
            return false
        }
        if (SessionManager.isGraceActive()) {
            Log.i("DoomscrollGuard", "ThresholdEngine: Grace period is active, skipping checks.")
            return false
        }

        // For testing: Hardcode limit to 10 seconds (10 * 1000L)
        val limitMs = 10 * 1000L
        
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
