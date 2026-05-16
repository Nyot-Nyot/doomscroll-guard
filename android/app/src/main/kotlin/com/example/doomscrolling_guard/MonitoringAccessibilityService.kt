package com.example.doomscrolling_guard

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.util.Log

class MonitoringAccessibilityService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            val prefs = getSharedPreferences("doomscroll_prefs", Context.MODE_PRIVATE)
            val targetApps = prefs.getStringSet("targetApps", emptySet()) ?: emptySet()
            
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
