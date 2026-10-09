package com.example.sos_eltvedtem

import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class AlertPopupActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        val titleText = intent.getStringExtra("EXTRA_TITLE") ?: "🚨 Értesítés"
        val recipientText = intent.getStringExtra("EXTRA_RECIPIENTS") ?: ""
        val messageText = intent.getStringExtra("EXTRA_MESSAGE") ?: "Az üzenet elküldve."

        val cardBackground = GradientDrawable().apply {
            setColor(Color.parseColor("#1F2937"))
            cornerRadius = 32f
            setStroke(3, Color.parseColor("#374151"))
        }

        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            background = cardBackground
            setPadding(50, 50, 50, 40)
        }

        // Címsor (Nagy, zöld)
        val tvTitle = TextView(this).apply {
            text = titleText
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setTextColor(Color.parseColor("#34D399"))
            paint.isFakeBoldText = true
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }

        // Kinek ment el? (Sárgás-fehér, kiemelt felirat: pl. "Címzett: Fiam")
        val tvRecipients = TextView(this).apply {
            text = if (recipientText.isNotBlank()) "📨 Értesítve:\n$recipientText" else ""
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
            setTextColor(Color.parseColor("#FBBF24")) // Meleg sárga figyelemfelkeltő szín
            paint.isFakeBoldText = true
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 20)
        }

        // További infók (távolság, koordináta)
        val tvMessage = TextView(this).apply {
            text = messageText
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setTextColor(Color.parseColor("#E5E7EB"))
            gravity = Gravity.CENTER
            setLineSpacing(5f, 1.1f)
            setPadding(0, 0, 0, 30)
        }

        // Rendben gomb
        val buttonBackground = GradientDrawable().apply {
            setColor(Color.parseColor("#2563EB"))
            cornerRadius = 16f
        }

        val btnClose = Button(this).apply {
            text = "Rendben"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTextColor(Color.WHITE)
            paint.isFakeBoldText = true
            background = buttonBackground
            setPadding(30, 20, 30, 20)
            setOnClickListener {
                finish()
            }
        }

        rootLayout.addView(tvTitle)
        if (recipientText.isNotBlank()) {
            rootLayout.addView(tvRecipients)
        }
        rootLayout.addView(tvMessage)
        rootLayout.addView(btnClose)

        setContentView(rootLayout)
    }
}