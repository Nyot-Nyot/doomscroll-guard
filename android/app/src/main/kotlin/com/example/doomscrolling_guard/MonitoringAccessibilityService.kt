package com.example.doomscrolling_guard

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.util.Log

class MonitoringAccessibilityService : AccessibilityService() {
    companion object {
        var isServiceConnected = false
    }

    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private var debounceRunnable: Runnable? = null
    private var lastSeenPackage: String? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceConnected = true
        Log.i("DoomscrollGuard", "MonitoringAccessibilityService: Connected")
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        isServiceConnected = false
        Log.i("DoomscrollGuard", "MonitoringAccessibilityService: Unbound")
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        isServiceConnected = false
        lastSeenPackage = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            val prefs = getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
            val targetApps = prefs.getStringSet("targetApps", emptySet()) ?: emptySet()
            
            if (packageName == this.packageName) {
                // Ignore our own package (app or overlay window) to prevent disrupting active tracking session
                return
            }
            
            if (targetApps.contains(packageName)) {
                Log.i("DoomscrollGuard", "DSG Monitoring: Opened $packageName")
                SessionManager.onAppOpened(this, packageName)
            } else {
                SessionManager.onAppClosed(this)
            }
        }
    }

    override fun onInterrupt() {
        // Implementation for Phase 1 - Major Task 1.2
    }
}
