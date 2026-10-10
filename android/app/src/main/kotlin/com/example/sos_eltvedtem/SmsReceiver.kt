package com.example.sos_eltvedtem

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
            val fullBody = java.lang.StringBuilder()
            var sender = ""

            for (msg in messages) {
                if (sender.isEmpty()) {
                    sender = msg.originatingAddress ?: ""
                }
                fullBody.append(msg.messageBody)
            }

            val content = fullBody.toString()

            if (content.contains("SOS SEGÉLYKÉRÉS") || content.contains("HELYZETJELENTÉS")) {
                val popupIntent = Intent(context, AlertPopupActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra("sms_sender", sender)
                    putExtra("sms_body", content)
                }

                try {
                    context.startActivity(popupIntent)
                } catch (t: Throwable) {
                    t.printStackTrace()
                }
            }
        }
    }
}