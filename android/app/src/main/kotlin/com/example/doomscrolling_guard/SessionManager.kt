package com.example.doomscrolling_guard

import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log
import java.util.Calendar

object SessionManager {
    var currentSessionApp: String? = null
    var sessionStartTime: Long = 0L

    // Tracks the monotonic maximum reported usage so far for a specific day, preventing drops.
    private val maxUsageReported = mutableMapOf<String, Long>()

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
            
            // To be instantly accurate on close, we force an update of the monotonic value 
            // by calling getRealtimeDailyUsage right when it closes.
            getRealtimeDailyUsage(context, packageName, isClosing = true)

            currentSessionApp = null
            sessionStartTime = 0L
        }
    }

    fun getDailyUsageStats(context: Context, packageName: String): Long {
        return getRealtimeDailyUsage(context, packageName)
    }

    fun getRealtimeDailyUsage(context: Context, packageName: String, isClosing: Boolean = false): Long {
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
        
        var currentOngoingMs = 0L
        if (currentSessionApp == packageName) {
            currentOngoingMs = System.currentTimeMillis() - sessionStartTime
        }

        // calculated incorporates the slowly-updating androidUsageTime + our live session Ms
        val calculated = androidUsageTime + currentOngoingMs

        val dayKey = "${packageName}_${calendar.timeInMillis}"
        val maxSeenToday = maxUsageReported[dayKey] ?: 0L
        
        // Ensure monotonic guarantee: do not drop time if androidUsageTime hasn't caught up
        var finalReport = maxOf(calculated, maxSeenToday)
        
        // If we are actively closing, the final duration is exactly accounted for, so we must bake it into maxSeen
        if (isClosing) {
            finalReport = maxOf(maxSeenToday + currentOngoingMs, androidUsageTime)
        }

        maxUsageReported[dayKey] = finalReport
        return finalReport
    }

    var snoozeUntil: Long = 0L
    var gracePeriodUntil: Long = 0L

    fun snooze(minutes: Int) {
        snoozeUntil = System.currentTimeMillis() + minutes * 60 * 1000L
        Log.i("DoomscrollGuard", "SessionManager: Snoozed until $snoozeUntil (${minutes} mins)")
    }

    fun grantGracePeriod(minutes: Int) {
        gracePeriodUntil = System.currentTimeMillis() + minutes * 60 * 1000L
        Log.i("DoomscrollGuard", "SessionManager: Grace period granted until $gracePeriodUntil (${minutes} mins)")
    }

    fun isSnoozed(): Boolean {
        return System.currentTimeMillis() < snoozeUntil
    }

    fun isGraceActive(): Boolean {
        return System.currentTimeMillis() < gracePeriodUntil
    }

    fun resetSessionState() {
        currentSessionApp = null
        sessionStartTime = 0L
        snoozeUntil = 0L
        gracePeriodUntil = 0L
        Log.i("DoomscrollGuard", "SessionManager: Session state reset")
    }
}
