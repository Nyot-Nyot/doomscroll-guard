package com.example.doomscrolling_guard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class MonitoringService : Service() {
    companion object {
        const val CHANNEL_ID = "DoomscrollGuardChannel"
        const val NOTIFICATION_ID = 1001
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Background monitoring tasks will be linked here
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // Not binding to activities, explicitly started
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Doomscroll Guard Active",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows that Doomscroll Guard is actively monitoring"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Doomscroll Guard")
            .setContentText("Monitoring your scrolling habits...")
            .setSmallIcon(android.R.drawable.ic_dialog_info) // System icon fallback
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
