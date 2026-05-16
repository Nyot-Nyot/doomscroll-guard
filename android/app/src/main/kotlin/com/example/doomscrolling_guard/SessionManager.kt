package com.example.doomscrolling_guard

import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log
import java.util.Calendar

object SessionManager {
    var currentSessionApp: String? = null
    var sessionStartTime: Long = 0L

    fun onAppOpened(context: Context, packageName: String) {
        if (currentSessionApp != packageName) {
            if (currentSessionApp != null) {
                onAppClosed(context, currentSessionApp!!)
            }

            Log.i("DoomscrollGuard", "SessionManager: Started tracking $packageName")
            currentSessionApp = packageName
            sessionStartTime = System.currentTimeMillis()
        }
    }

    fun onAppClosed(context: Context, packageName: String? = currentSessionApp) {
        if (packageName != null && currentSessionApp == packageName) {
            val durationMs = System.currentTimeMillis() - sessionStartTime
            Log.i("DoomscrollGuard", "SessionManager: Ended tracking $packageName. Session lasted ${durationMs}ms")
            
            val prefs = context.getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
            val cumulativeTime = prefs.getLong("usage_$packageName", 0L)
            prefs.edit().putLong("usage_$packageName", cumulativeTime + durationMs).apply()

            currentSessionApp = null
            sessionStartTime = 0L
        }
    }

    fun getDailyUsageStats(context: Context, packageName: String): Long {
        val prefs = context.getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val stats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
        val packageStat = stats?.find { it.packageName == packageName }
        
        val androidUsageTime = packageStat?.totalTimeInForeground ?: 0L
        val ourTrackingTime = prefs.getLong("usage_$packageName", 0L)
        
        return maxOf(androidUsageTime, ourTrackingTime)
    }

    fun getRealtimeDailyUsage(context: Context, packageName: String): Long {
        var currentOngoingMs = 0L
        if (currentSessionApp == packageName) {
            currentOngoingMs = System.currentTimeMillis() - sessionStartTime
        }
        return getDailyUsageStats(context, packageName) + currentOngoingMs
    }
}
