package com.example.doomscrolling_guard

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.util.TypedValue
import android.util.Log

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val targetPackage = intent?.getStringExtra("target_package") ?: ""
        showOverlay(targetPackage)
        return START_NOT_STICKY
    }

    private fun showOverlay(targetPackage: String) {
        if (overlayView != null) return // Already showing overlay

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val density = resources.displayMetrics.density

        // 1. Root Full-screen Layout
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#801F1D1A")) // 50% dimmed warm dark background
        }

        // 2. Central Card
        val cardLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            val pad = (24 * density).toInt()
            setPadding(pad, pad, pad, pad)
            
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                setColor(Color.parseColor("#F6F4EF")) // Warm Off White
                cornerRadius = 24 * density
            }
        }

        val cardWidth = (320 * density).toInt()
        val cardParams = LinearLayout.LayoutParams(cardWidth, LinearLayout.LayoutParams.WRAP_CONTENT)
        rootLayout.addView(cardLayout, cardParams)

        // 3. Card Title
        val titleText = TextView(this).apply {
            text = "You've been scrolling for a while"
            setTextColor(Color.parseColor("#2B2B2B")) // Deep Charcoal
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            gravity = Gravity.CENTER
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        val titleParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            bottomMargin = (12 * density).toInt()
        }
        cardLayout.addView(titleText, titleParams)

        // 4. Card Description
        val descText = TextView(this).apply {
            text = "Take a short break before continuing."
            setTextColor(Color.parseColor("#6E6A63")) // Warm Gray
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            gravity = Gravity.CENTER
        }
        val descParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            bottomMargin = (28 * density).toInt()
        }
        cardLayout.addView(descText, descParams)

        // 5. Button Helper function
        fun createStyledButton(textStr: String, bgHex: String, textHex: String, onClick: () -> Unit): Button {
            return Button(this).apply {
                text = textStr
                isAllCaps = false
                setTextColor(Color.parseColor(textHex))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                background = GradientDrawable().apply {
                    shape = GradientDrawable.RECTANGLE
                    setColor(Color.parseColor(bgHex))
                    cornerRadius = 14 * density
                }
                setOnClickListener { onClick() }
            }
        }

        // 6. Action Button: Take a Break
        val breakBtn = createStyledButton("Take a Break", "#6B705C", "#FFFFFF") {
            Log.i("DoomscrollGuard", "OverlayService: Take a Break clicked")
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
            SessionManager.resetSessionState()
            stopSelf()
        }
        val btnParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            (48 * density).toInt()
        ).apply {
            bottomMargin = (12 * density).toInt()
        }
        cardLayout.addView(breakBtn, btnParams)

        // 7. Action Button: Snooze
        val snoozeBtn = createStyledButton("Snooze (10m)", "#CB997E", "#FFFFFF") {
            Log.i("DoomscrollGuard", "OverlayService: Snooze clicked")
            SessionManager.snooze(10)
            stopSelf()
        }
        cardLayout.addView(snoozeBtn, btnParams)

        // 8. Action Button: Continue Anyway / Dismiss
        val dismissBtn = Button(this).apply {
            text = "Continue anyway"
            isAllCaps = false
            setTextColor(Color.parseColor("#6E6A63")) // Warm Gray
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                setColor(Color.parseColor("#ECE7DE")) // Soft Sand
                cornerRadius = 14 * density
            }
            setOnClickListener {
                Log.i("DoomscrollGuard", "OverlayService: Dismiss clicked")
                SessionManager.grantGracePeriod(5)
                stopSelf()
            }
        }
        val dismissParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            (48 * density).toInt()
        )
        cardLayout.addView(dismissBtn, dismissParams)

        // 9. Window Layout Params
        val layoutParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        )

        overlayView = rootLayout
        windowManager?.addView(overlayView, layoutParams)
    }

    override fun onDestroy() {
        if (overlayView != null) {
            windowManager?.removeView(overlayView)
            overlayView = null
        }
        SessionManager.isInterventionActive = false
        super.onDestroy()
    }
}
