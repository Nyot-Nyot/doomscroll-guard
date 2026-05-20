package com.example.doomscrolling_guard

import android.content.Context
import android.util.Log
import java.util.Calendar

object SessionManager {
    var currentSessionApp: String? = null
    var sessionStartTime: Long = 0L

    private fun getTodayStartMillis(): Long {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return calendar.timeInMillis
    }

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
            val elapsedMs = System.currentTimeMillis() - sessionStartTime
            Log.i("DoomscrollGuard", "SessionManager: Ended tracking $packageName. Session lasted ${elapsedMs}ms")
            
            // Save last active session duration
            lastSessionDurationMap[packageName] = elapsedMs
            
            val todayStart = getTodayStartMillis()
            val prefs = context.getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
            val baseKey = "usage_${packageName}_$todayStart"
            val baseUsage = prefs.getLong(baseKey, 0L)
            
            prefs.edit().putLong(baseKey, baseUsage + elapsedMs).apply()

            // Update longest session
            val key = getDayKey()
            val storedMax = longestSessionMap[key] ?: 0L
            longestSessionMap[key] = maxOf(elapsedMs, storedMax)

            currentSessionApp = null
            sessionStartTime = 0L
        }
    }

    fun persistCurrentSessionTime(context: Context) {
        val app = currentSessionApp
        if (app != null && sessionStartTime > 0L) {
            val elapsedMs = System.currentTimeMillis() - sessionStartTime
            
            // Save last active session duration
            lastSessionDurationMap[app] = elapsedMs
            
            // 1. Update daily usage
            val todayStart = getTodayStartMillis()
            val prefs = context.getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
            val baseKey = "usage_${app}_$todayStart"
            val baseUsage = prefs.getLong(baseKey, 0L)
            prefs.edit().putLong(baseKey, baseUsage + elapsedMs).apply()
            Log.i("DoomscrollGuard", "SessionManager: Persisted ongoing session for $app of ${elapsedMs}ms. New daily total: ${baseUsage + elapsedMs}ms")
            
            // 2. Update longest session
            val key = getDayKey()
            val storedMax = longestSessionMap[key] ?: 0L
            longestSessionMap[key] = maxOf(elapsedMs, storedMax)
            
            // 3. Reset sessionStartTime to now so we only count new duration going forward
            sessionStartTime = System.currentTimeMillis()
        }
    }

    fun getDailyUsageStats(context: Context, packageName: String): Long {
        return getRealtimeDailyUsage(context, packageName)
    }

    fun getRealtimeDailyUsage(context: Context, packageName: String, isClosing: Boolean = false): Long {
        val todayStart = getTodayStartMillis()
        val prefs = context.getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
        val baseKey = "usage_${packageName}_$todayStart"
        val baseUsage = prefs.getLong(baseKey, 0L)

        return if (currentSessionApp == packageName && sessionStartTime > 0L) {
            val currentOngoingMs = System.currentTimeMillis() - sessionStartTime
            baseUsage + currentOngoingMs
        } else {
            baseUsage
        }
    }

    private val lastSessionDurationMap = mutableMapOf<String, Long>()

    fun getCurrentSessionDuration(packageName: String): Long {
        if (currentSessionApp == packageName && sessionStartTime > 0L) {
            return System.currentTimeMillis() - sessionStartTime
        }
        return lastSessionDurationMap[packageName] ?: 0L
    }

    private val warningCountMap = mutableMapOf<String, Int>()

    private fun getDayKey(): String {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return calendar.timeInMillis.toString()
    }

    fun getWarningCountToday(): Int {
        return warningCountMap[getDayKey()] ?: 0
    }

    fun incrementWarningCount() {
        val key = getDayKey()
        val current = warningCountMap[key] ?: 0
        warningCountMap[key] = current + 1
        Log.i("DoomscrollGuard", "SessionManager: warningCount incremented to ${current + 1} for $key")
    }

    private val longestSessionMap = mutableMapOf<String, Long>()

    fun getLongestSessionToday(): Long {
        val key = getDayKey()
        val currentSessionDuration = if (currentSessionApp != null && sessionStartTime > 0L) {
            System.currentTimeMillis() - sessionStartTime
        } else {
            0L
        }
        val storedMax = longestSessionMap[key] ?: 0L
        val maxSession = maxOf(currentSessionDuration, storedMax)
        longestSessionMap[key] = maxSession
        return maxSession
    }

    var snoozeUntil: Long = 0L
    var gracePeriodUntil: Long = 0L
    var isInterventionActive: Boolean = false

    fun snooze(minutes: Int) {
        // For testing: Hardcode snooze to 5 seconds (5 * 1000L)
        snoozeUntil = System.currentTimeMillis() + 5 * 1000L
        sessionStartTime = System.currentTimeMillis() // Reset session duration start
        Log.i("DoomscrollGuard", "SessionManager: Snoozed until $snoozeUntil (5 seconds for testing)")
    }

    fun grantGracePeriod(minutes: Int) {
        gracePeriodUntil = System.currentTimeMillis() + minutes * 60 * 1000L
        sessionStartTime = System.currentTimeMillis() // Reset session duration start
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
