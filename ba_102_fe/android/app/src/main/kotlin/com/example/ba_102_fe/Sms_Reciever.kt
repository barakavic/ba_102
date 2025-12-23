package com.example.ba_102_fe

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {
    companion object{
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context?, intent: Intent? ){
        if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION){
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            val fullBody = StringBuilder()
            var sender: String? = null
            var timestamp: Long = 0

            for (message in messages){
                if (sender == null) sender = message.originatingAddress
                fullBody.append(message.messageBody)
                timestamp = message.timestampMillis
            }

            val body = fullBody.toString()
            println("SMS Received from $sender: $body")

            val isMpesa = sender?.contains("MPESA", ignoreCase = true) == true || 
                         sender?.contains("Safaricom", ignoreCase = true) == true ||
                         body.contains("MPESA", ignoreCase = true) || 
                         body.contains("M-PESA", ignoreCase = true) || 
                         body.contains("Confirmed", ignoreCase = true)

            if (isMpesa) {
                println("Processing as M-Pesa/Safaricom transaction")
                if (methodChannel == null) {
                    println("Error: methodChannel is null. Flutter engine might not be running.")
                }
                methodChannel?.invokeMethod("onSmsReceived", mapOf(
                    "sender" to sender,
                    "body" to body,
                    "timestamp" to timestamp
                ))
            } else {
                println("SMS ignored (not identified as transaction)")
            }
        }
    }
}
