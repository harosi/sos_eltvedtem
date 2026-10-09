package com.example.sos_eltvedtem

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.speech.tts.TextToSpeech
import android.telephony.SmsManager
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Locale

class BatteryAlertReceiver : BroadcastReceiver() {

    private var tts: TextToSpeech? = null

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("battery_alert_prefs", Context.MODE_PRIVATE)

        when (intent.action) {
            // Ha töltőre teszik vagy visszatér az akku, visszaállítjuk az állapotot a következő lemerüléshez
            Intent.ACTION_POWER_CONNECTED,
            Intent.ACTION_BATTERY_OKAY -> {
                prefs.edit().putBoolean("battery_alert_sent", false).apply()
                return
            }

            // Amikor eléri a kritikus szintet (kb. 10-15%)
            Intent.ACTION_BATTERY_LOW -> {
                // 1. Hangos figyelmeztetés a készüléken
                speak(context, "Figyelem! Az akkumulátor szintje alacsony, kérlek tedd töltőre a telefont!")
                Toast.makeText(context, "⚠️ Figyelem: Akkumulátor 10% alatt!", Toast.LENGTH_LONG).show()

                // 2. Megnézzük, hogy erre a merülési ciklusra küldtünk-e már SMS-t
                val alreadySent = prefs.getBoolean("battery_alert_sent", false)
                if (alreadySent) {
                    return // SMS-t nem ismétlünk feleslegesen
                }

                // 3. Adatok betöltése
                val widgetData = HomeWidgetPlugin.getData(context)
                val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

                var targetPhones = widgetData.getString("target_phones", "") ?: ""
                if (targetPhones.isBlank()) {
                    targetPhones = flutterPrefs.getString("flutter.target_phones", "") ?: ""
                }

                var senderPhone = widgetData.getString("my_sender_phone", "") ?: ""
                if (senderPhone.isBlank()) {
                    senderPhone = widgetData.getString("my_phone", "") ?: ""
                }
                if (senderPhone.isBlank()) {
                    senderPhone = flutterPrefs.getString("flutter.my_sender_phone", "") ?: ""
                }

                if (targetPhones.isNotBlank()) {
                    sendBatterySms(context, targetPhones, senderPhone)
                    // Bejegyezzük, hogy az SMS elment erre a ciklusra
                    prefs.edit().putBoolean("battery_alert_sent", true).apply()
                }
            }
        }
    }

    private fun speak(context: Context, text: String) {
        try {
            tts = TextToSpeech(context.applicationContext) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    tts?.language = Locale("hu", "HU")
                    tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
                }
            }
        } catch (_: Exception) {}
    }

    private fun sendBatterySms(context: Context, targetPhones: String, senderPhone: String) {
        val message = buildString {
            append("⚠️ [SOS ELTÉVEDTEM - AKKU RIASZTÁS]\n")
            if (senderPhone.isNotBlank()) {
                append("📞 Telefon száma: ").append(senderPhone).append("\n")
            }
            append("A telefon akkumulátora 10% alá merült! Hamarosan kikapcsolhat, kérjük hívják fel vagy töltsék fel a telefont!")
        }

        try {
            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }

            val cleanList = targetPhones.replace(";", ",")
            val phoneList = cleanList.split(",").map { it.trim() }.filter { it.isNotBlank() }

            for (phone in phoneList) {
                val parts = smsManager.divideMessage(message)
                if (parts.size > 1) {
                    smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                } else {
                    smsManager.sendTextMessage(phone, null, message, null, null)
                }
            }
        } catch (_: Exception) {}
    }
}