package com.example.doomscrolling_guard

import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log
import java.util.Calendar

object SessionManager {
    var currentSessionApp: String? = null
    var sessionStartTime: Long = 0L
    var sessionStartAndroidUsage: Long = 0L

    // Tracks the monotonic maximum reported usage so far for a specific day, preventing drops.
    private val maxUsageReported = mutableMapOf<String, Long>()

    private fun getAndroidUsageToday(context: Context, packageName: String): Long {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val statsMap = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        val packageStat = statsMap[packageName]
        
        return packageStat?.totalTimeInForeground ?: 0L
    }

    fun onAppOpened(context: Context, packageName: String) {
        if (currentSessionApp != packageName) {
            if (currentSessionApp != null) {
                onAppClosed(context, currentSessionApp!!)
            }

            Log.i("DoomscrollGuard", "SessionManager: Started tracking $packageName")
            currentSessionApp = packageName
            sessionStartTime = System.currentTimeMillis()
            sessionStartAndroidUsage = getAndroidUsageToday(context, packageName)
        }
    }

    fun onAppClosed(context: Context, packageName: String? = currentSessionApp) {
        if (packageName != null && currentSessionApp == packageName) {
            val durationMs = System.currentTimeMillis() - sessionStartTime
            Log.i("DoomscrollGuard", "SessionManager: Ended tracking $packageName. Session lasted ${durationMs}ms")
            
            // To be instantly accurate on close, we force an update of the monotonic value 
            getRealtimeDailyUsage(context, packageName, isClosing = true)

            currentSessionApp = null
            sessionStartTime = 0L
            sessionStartAndroidUsage = 0L
        }
    }

    fun getDailyUsageStats(context: Context, packageName: String): Long {
        return getRealtimeDailyUsage(context, packageName)
    }

    fun getRealtimeDailyUsage(context: Context, packageName: String, isClosing: Boolean = false): Long {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val dayKey = "${packageName}_${calendar.timeInMillis}"

        if (currentSessionApp == packageName) {
            val currentOngoingMs = System.currentTimeMillis() - sessionStartTime
            val calculated = sessionStartAndroidUsage + currentOngoingMs
            val maxSeenToday = maxUsageReported[dayKey] ?: 0L
            val finalReport = maxOf(calculated, maxSeenToday)
            maxUsageReported[dayKey] = finalReport
            return finalReport
        } else {
            val androidUsageTime = getAndroidUsageToday(context, packageName)
            val maxSeenToday = maxUsageReported[dayKey] ?: 0L
            val finalReport = maxOf(androidUsageTime, maxSeenToday)
            maxUsageReported[dayKey] = finalReport
            return finalReport
        }
    }

    fun getCurrentSessionDuration(packageName: String): Long {
        if (currentSessionApp == packageName && sessionStartTime > 0L) {
            return System.currentTimeMillis() - sessionStartTime
        }
        return 0L
    }

    var snoozeUntil: Long = 0L
    var gracePeriodUntil: Long = 0L
    var isInterventionActive: Boolean = false

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
        isInterventionActive = false
        Log.i("DoomscrollGuard", "SessionManager: Session state reset")
    }
}
