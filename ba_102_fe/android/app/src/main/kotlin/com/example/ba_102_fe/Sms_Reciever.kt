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

            for (message in messages){
                val sender = message.originatingAddress
                val body = message.messageBody

                if (sender == "MPESA" || body.contains("M-PESA", ignoreCase = true)){
                    methodChannel?.invokeMethod("onSmsRecieved", mapOf(
                        "sender" to sender,
                        "body" to body,
                        "timestamp" to message.timestampMillis
                    ))
                }
            }
        }
    }
}
