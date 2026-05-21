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
        var isRunning = false
        var isPaused = false
    }

    private var screenOffReceiver: android.content.BroadcastReceiver? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        isPaused = false
        createNotificationChannel()

        screenOffReceiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                    android.util.Log.i("DoomscrollGuard", "MonitoringService: Screen turned off, closing active session.")
                    SessionManager.onAppClosed(this@MonitoringService)
                }
            }
        }
        val filter = android.content.IntentFilter(Intent.ACTION_SCREEN_OFF)
        registerReceiver(screenOffReceiver, filter)
    }

    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    private val checkRunnable = object : Runnable {
        override fun run() {
            if (!MonitoringAccessibilityService.isServiceConnected) {
                android.util.Log.w("DoomscrollGuard", "MonitoringService: Accessibility service disconnected/revoked. Stopping service.")
                SessionManager.resetSessionState()
                stopSelf()
                return
            }

            val currentApp = SessionManager.currentSessionApp
            if (currentApp != null) {
                ThresholdEngine.checkUsage(this@MonitoringService, currentApp)
            }
            handler.postDelayed(this, 5000L) // Poll every 5 seconds
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        handler.removeCallbacks(checkRunnable)
        handler.post(checkRunnable)
        
        return START_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        isPaused = false
        screenOffReceiver?.let { unregisterReceiver(it) }
        handler.removeCallbacks(checkRunnable)
        super.onDestroy()
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
