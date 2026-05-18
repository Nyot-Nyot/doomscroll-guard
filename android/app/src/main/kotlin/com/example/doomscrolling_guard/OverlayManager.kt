package com.example.doomscrolling_guard

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object OverlayManager {
    const val INTERVENTION_CHANNEL_ID = "DoomscrollGuardInterventionChannel"
    const val INTERVENTION_NOTIFICATION_ID = 1002

    fun showIntervention(context: Context, packageName: String) {
        if (SessionManager.isInterventionActive) {
            return // Skip if already active to prevent duplicate triggers/notifs
        }
        
        SessionManager.isInterventionActive = true

        if (Settings.canDrawOverlays(context)) {
            Log.i("DoomscrollGuard", "OverlayManager: Displaying overlay for $packageName")
            val intent = Intent(context, OverlayService::class.java).apply {
                putExtra("target_package", packageName)
            }
            context.startService(intent)
        } else {
            Log.w("DoomscrollGuard", "OverlayManager: Overlay permission missing! Triggering fallback notification.")
            showFallbackNotification(context, packageName)
        }
    }

    fun dismissIntervention(context: Context) {
        val intent = Intent(context, OverlayService::class.java)
        context.stopService(intent)
    }

    private fun showFallbackNotification(context: Context, packageName: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create high-importance channel for real-time alert
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                INTERVENTION_CHANNEL_ID,
                "Doomscroll Guard Warnings",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts you when your doomscrolling threshold is exceeded"
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Action: Snooze
        val snoozeIntent = Intent(context, OverlayActionReceiver::class.java).apply {
            action = OverlayActionReceiver.ACTION_SNOOZE
            putExtra("target_package", packageName)
        }
        val snoozePendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        // Action: Take a Break
        val breakIntent = Intent(context, OverlayActionReceiver::class.java).apply {
            action = OverlayActionReceiver.ACTION_BREAK
            putExtra("target_package", packageName)
        }
        val breakPendingIntent = PendingIntent.getBroadcast(
            context,
            2,
            breakIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        // Action: Dismiss
        val dismissIntent = Intent(context, OverlayActionReceiver::class.java).apply {
            action = OverlayActionReceiver.ACTION_DISMISS
            putExtra("target_package", packageName)
        }
        val dismissPendingIntent = PendingIntent.getBroadcast(
            context,
            3,
            dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val builder = NotificationCompat.Builder(context, INTERVENTION_CHANNEL_ID)
            .setContentTitle("You've been scrolling for a while")
            .setContentText("Take a short break before continuing.")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setOngoing(true) // Prevent accidental swipe away to ensure attention
            .addAction(android.R.drawable.ic_lock_power_off, "Take a Break", breakPendingIntent)
            .addAction(android.R.drawable.ic_media_play, "Snooze (10m)", snoozePendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Dismiss (5m)", dismissPendingIntent)

        notificationManager.notify(INTERVENTION_NOTIFICATION_ID, builder.build())
    }
}
