package com.example.doomscrolling_guard

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class OverlayActionReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_SNOOZE = "com.example.doomscrolling_guard.ACTION_SNOOZE"
        const val ACTION_DISMISS = "com.example.doomscrolling_guard.ACTION_DISMISS"
        const val ACTION_BREAK = "com.example.doomscrolling_guard.ACTION_BREAK"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val action = intent.action
        val targetPackage = intent.getStringExtra("target_package")
        Log.i("DoomscrollGuard", "OverlayActionReceiver: Received action $action for package $targetPackage")

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(OverlayManager.INTERVENTION_NOTIFICATION_ID)

        when (action) {
            ACTION_SNOOZE -> {
                SessionManager.snooze(10) // 10 minutes snooze
            }
            ACTION_DISMISS -> {
                SessionManager.grantGracePeriod(5) // 5 minutes grace period
            }
            ACTION_BREAK -> {
                // Return user to Home screen
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(homeIntent)
                SessionManager.resetSessionState()
            }
        }
    }
}
