package com.example.sos_eltvedtem

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.telephony.SmsManager
import android.widget.RemoteViews
import android.widget.Toast
import androidx.core.app.NotificationCompat
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Locale

class SosWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.sos_widget_layout)

            val sosIntent = Intent(context, SilentAlertReceiver::class.java).apply {
                action = ACTION_TRIGGER_SOS
                putExtra("IS_EMERGENCY", true)
            }
            val sosPendingIntent = PendingIntent.getBroadcast(
                context,
                101,
                sosIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_sos, sosPendingIntent)

            val gpsIntent = Intent(context, SilentAlertReceiver::class.java).apply {
                action = ACTION_TRIGGER_GPS
                putExtra("IS_EMERGENCY", false)
            }
            val gpsPendingIntent = PendingIntent.getBroadcast(
                context,
                102,
                gpsIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_gps, gpsPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    companion object {
        const val ACTION_TRIGGER_SOS = "com.example.sos_eltvedtem.ACTION_TRIGGER_SOS"
        const val ACTION_TRIGGER_GPS = "com.example.sos_eltvedtem.ACTION_TRIGGER_GPS"
    }
}

class SilentAlertReceiver : BroadcastReceiver() {

    private var tts: TextToSpeech? = null

    companion object {
        private const val COOLDOWN_MS: Long = 15000
        private const val DOUBLE_TAP_WINDOW_MS: Long = 3000
        private const val CHANNEL_ID = "sos_alert_popup_channel"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val guardPrefs = context.getSharedPreferences("sos_guard_prefs", Context.MODE_PRIVATE)
        val currentTime = System.currentTimeMillis()

        val isSending = guardPrefs.getBoolean("is_currently_sending", false)
        val lastTriggerTime = guardPrefs.getLong("last_trigger_timestamp", 0L)
        val elapsedSinceTrigger = currentTime - lastTriggerTime

        if (isSending || elapsedSinceTrigger < COOLDOWN_MS) {
            val remSec = ((COOLDOWN_MS - elapsedSinceTrigger) / 1000) + 1
            if (remSec in 1..15) {
                Toast.makeText(context, "Kérlek várj még $remSec másodpercet!", Toast.LENGTH_SHORT).show()
            }
            return
        }

        val isEmergency = intent.getBooleanExtra("IS_EMERGENCY", true)
        val actionKey = if (isEmergency) "last_tap_sos" else "last_tap_gps"
        val lastTapTime = guardPrefs.getLong(actionKey, 0L)
        val elapsedSinceTap = currentTime - lastTapTime

        if (lastTapTime == 0L || elapsedSinceTap > DOUBLE_TAP_WINDOW_MS) {
            guardPrefs.edit().putLong(actionKey, currentTime).apply()
            vibrate(context, 100)

            val promptMsg = if (isEmergency) "Nyomd meg újra a segélykéréshez!" else "Nyomd meg újra a küldéshez!"
            Toast.makeText(context, promptMsg, Toast.LENGTH_SHORT).show()
            speak(context, "Nyomd meg még egyszer a küldéshez!")
            return
        }

        // Dupla érintés sikeres: azonnali reteszelés
        guardPrefs.edit()
            .putLong(actionKey, 0L)
            .putBoolean("is_currently_sending", true)
            .putLong("last_trigger_timestamp", currentTime)
            .apply()

        vibrate(context, 250)

        val widgetData = HomeWidgetPlugin.getData(context)
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // --- LICENC ELLENŐRZÉSE ---
        val isLicensed = widgetData.getBoolean("is_licensed", false) || flutterPrefs.getBoolean("flutter.is_licensed", false)
        if (!isLicensed) {
            guardPrefs.edit().putBoolean("is_currently_sending", false).apply()
            val noLicenseMsg = "⚠️ Az app nincs aktiválva! Kérjük aktiválja a Beállításokban."
            Toast.makeText(context, noLicenseMsg, Toast.LENGTH_LONG).show()
            speak(context, "Az alkalmazás nincs aktiválva. Kérjük nyissa meg a beállításokat.")
            return
        }

        // 1. Beírt név beolvasása (HomeWidget vagy FlutterSharedPreferences)
        var contactName = widgetData.getString("target_name", "")?.trim() ?: ""
        if (contactName.isBlank()) {
            contactName = widgetData.getString("target_names", "")?.trim() ?: ""
        }
        if (contactName.isBlank()) {
            contactName = flutterPrefs.getString("flutter.target_name", "")?.trim() ?: ""
        }

        // 2. Beírt telefonszám beolvasása
        var targetPhones = widgetData.getString("target_phones", "")?.trim() ?: ""
        if (targetPhones.isBlank()) {
            targetPhones = flutterPrefs.getString("flutter.target_phones", "")?.trim() ?: ""
        }

        // 3. Saját szám
        var senderPhone = widgetData.getString("my_sender_phone", "")?.trim() ?: ""
        if (senderPhone.isBlank()) {
            senderPhone = widgetData.getString("my_phone", "")?.trim() ?: ""
        }
        if (senderPhone.isBlank()) {
            senderPhone = flutterPrefs.getString("flutter.my_sender_phone", "")?.trim() ?: ""
        }

        if (targetPhones.isBlank()) {
            guardPrefs.edit().putBoolean("is_currently_sending", false).apply()
            Toast.makeText(context, "Nincs megadva telefonszám!", Toast.LENGTH_LONG).show()
            speak(context, "Hiba. Nincs megadva telefonszám.")
            return
        }

        fetchLocationAndSend(context, targetPhones, contactName, senderPhone, isEmergency)
    }

    private fun vibrate(context: Context, durationMs: Long) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vm?.defaultVibrator?.vibrate(VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                val v = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                @Suppress("DEPRECATION")
                v?.vibrate(durationMs)
            }
        } catch (_: Exception) {}
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

    @SuppressLint("MissingPermission")
    private fun fetchLocationAndSend(
        context: Context,
        targetPhones: String,
        contactName: String,
        senderPhone: String,
        isEmergency: Boolean
    ) {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
        if (locationManager == null) {
            sendSms(context, targetPhones, contactName, senderPhone, null, isEmergency)
            return
        }

        val isGpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val isNetworkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)

        var bestLocation: Location? = null

        try {
            if (isGpsEnabled) {
                bestLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            }
            if (bestLocation == null && isNetworkEnabled) {
                bestLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            }
        } catch (_: Exception) {}

        if (bestLocation != null) {
            sendSms(context, targetPhones, contactName, senderPhone, bestLocation, isEmergency)
            return
        }

        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                sendSms(context, targetPhones, contactName, senderPhone, location, isEmergency)
                try {
                    locationManager.removeUpdates(this)
                } catch (_: Exception) {}
            }
            @Deprecated("Deprecated in Java")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
            override fun onProviderEnabled(provider: String) {}
            override fun onProviderDisabled(provider: String) {}
        }

        try {
            if (isGpsEnabled) {
                locationManager.requestSingleUpdate(LocationManager.GPS_PROVIDER, listener, null)
            } else if (isNetworkEnabled) {
                locationManager.requestSingleUpdate(LocationManager.NETWORK_PROVIDER, listener, null)
            } else {
                sendSms(context, targetPhones, contactName, senderPhone, null, isEmergency)
            }
        } catch (e: Exception) {
            sendSms(context, targetPhones, contactName, senderPhone, null, isEmergency)
        }
    }

    private fun sendSms(
        context: Context,
        targetPhones: String,
        contactName: String,
        senderPhone: String,
        location: Location?,
        isEmergency: Boolean
    ) {
        val title = if (isEmergency) {
            "[SOS SEGÉLYKÉRÉS! Eltévedtem / segítségre van szükségem]"
        } else {
            "[HELYZETJELENTÉS - Jelenlegi pozícióm]"
        }

        val widgetData = HomeWidgetPlugin.getData(context)
        val homeLat = widgetData.getString("home_lat", "")?.toDoubleOrNull()
        val homeLng = widgetData.getString("home_lng", "")?.toDoubleOrNull()

        var distanceText = ""
        if (location != null && homeLat != null && homeLng != null) {
            val homeLoc = Location("home").apply {
                latitude = homeLat
                longitude = homeLng
            }
            val distMeters = location.distanceTo(homeLoc)
            distanceText = if (distMeters >= 1000) {
                String.format(Locale("hu", "HU"), "🏠 Távolság otthontól: kb. %.1f km\n", distMeters / 1000.0)
            } else {
                String.format(Locale("hu", "HU"), "🏠 Távolság otthontól: kb. %d m\n", distMeters.toInt())
            }
        }

        val messageText = buildString {
            append(title).append("\n")

            if (senderPhone.isNotBlank()) {
                append("📞 Segélykérő száma: ").append(senderPhone).append("\n")
            }

            if (distanceText.isNotEmpty()) {
                append(distanceText)
            }

            if (location != null) {
                val formattedLat = String.format(Locale.US, "%.5f", location.latitude)
                val formattedLng = String.format(Locale.US, "%.5f", location.longitude)

                append("📍 Helyzet: ").append(formattedLat).append(", ").append(formattedLng).append("\n")
                append("🗺️ Térkép: https://www.google.com/maps/search/?api=1&query=")
                    .append(formattedLat)
                    .append("%2C")
                    .append(formattedLng)
            } else {
                append("📍 Helyzet: GPS jel keresése sikertelen.")
            }
        }

        val guardPrefs = context.getSharedPreferences("sos_guard_prefs", Context.MODE_PRIVATE)

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
                val parts = smsManager.divideMessage(messageText)
                if (parts.size > 1) {
                    smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                } else {
                    smsManager.sendTextMessage(phone, null, messageText, null, null)
                }
            }

            val displayRecipient = if (contactName.isNotBlank()) {
                "$contactName\n$cleanList"
            } else {
                cleanList
            }

            val voiceMsg = if (contactName.isNotBlank()) {
                if (isEmergency) "Segélykérés elküldve neki: $contactName!" else "Helyzet elküldve neki: $contactName!"
            } else {
                if (isEmergency) "Segélykérés elküldve!" else "Helyzet elküldve!"
            }

            Toast.makeText(context, voiceMsg, Toast.LENGTH_SHORT).show()
            speak(context, voiceMsg)

            showPopupNotification(
                context,
                if (isEmergency) "🚨 Segélykérés elküldve!" else "📍 Helyzet elküldve!",
                displayRecipient,
                distanceText
            )

        } catch (e: Exception) {
            Toast.makeText(context, "Hiba az SMS küldésekor: " + e.message, Toast.LENGTH_LONG).show()
            speak(context, "Hiba történt, az üzenet nem ment el.")
        } finally {
            guardPrefs.edit().putBoolean("is_currently_sending", false).apply()
        }
    }

    private fun showPopupNotification(context: Context, title: String, recipients: String, message: String) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "SOS Riasztás Megerősítés",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "SOS és GPS állapotfelugró ablak"
                    enableVibration(true)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val popupIntent = Intent(context, AlertPopupActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("EXTRA_TITLE", title)
                putExtra("EXTRA_RECIPIENTS", recipients)
                putExtra("EXTRA_MESSAGE", message)
            }

            val fullScreenPendingIntent = PendingIntent.getActivity(
                context,
                105,
                popupIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText("Értesítve: $recipients")
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setContentIntent(fullScreenPendingIntent)
                .setFullScreenIntent(fullScreenPendingIntent, true)

            notificationManager.notify(999, builder.build())

            context.startActivity(popupIntent)
        } catch (_: Exception) {}
    }
}