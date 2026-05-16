package com.example.doomscrolling_guard

import android.content.Context
import android.util.Log

object ThresholdEngine {
    fun checkUsage(context: Context, packageName: String): Boolean {
        val prefs = context.getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
        val limitMinutes = prefs.getInt("thresholdMinutes", 20)
        // Convert to ms. If limit is 0, we can assume it's disabled, but let's just multiply.
        val limitMs = limitMinutes * 60 * 1000L
        
        val totalUsageMs = SessionManager.getRealtimeDailyUsage(context, packageName)
        
        if (totalUsageMs >= limitMs) {
            Log.w("DoomscrollGuard", "THRESHOLD REACHED FOR $packageName: $totalUsageMs ms >= $limitMs ms")
            // TODO: In Major Task 1.4, trigger the Overlay screen here!
            return true
        } else {
            Log.i("DoomscrollGuard", "Usage for $packageName is $totalUsageMs ms (Limit: $limitMs ms)")
            return false
        }
    }
}
