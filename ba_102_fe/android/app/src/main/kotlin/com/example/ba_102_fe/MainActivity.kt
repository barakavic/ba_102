package com.example.ba_102_fe

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Telephony
import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
class MainActivity : FlutterActivity(){
    private val CHANNEL = "com.example.ba_102_fe/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine){
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        SmsReceiver.methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            if (call.method == "fetchOldSms") {
                val since = call.argument<Long>("since")
                val messages = fetchHistoricalSms(since)
                result.success(messages)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun fetchHistoricalSms(since: Long?): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val cursor = contentResolver.query(
            android.provider.Telephony.Sms.CONTENT_URI,
            arrayOf("body", "address", "date"),
            if (since != null) "date > ?" else null,
            if (since != null) arrayOf(since.toString()) else null,
            "date DESC"
        )

        cursor?.use {
            val bodyIdx = it.getColumnIndex("body")
            val addrIdx = it.getColumnIndex("address")
            val dateIdx = it.getColumnIndex("date")

            while (it.moveToNext()) {
                val address = it.getString(addrIdx)
                val body = it.getString(bodyIdx)
                val date = it.getLong(dateIdx)

                // Filter for M-Pesa/Safaricom messages
                val isMpesa = address?.contains("MPESA", ignoreCase = true) == true || 
                             address?.contains("M-PESA", ignoreCase = true) == true ||
                             address?.contains("Safaricom", ignoreCase = true) == true ||
                             body?.contains("MPESA", ignoreCase = true) == true || 
                             body?.contains("M-PESA", ignoreCase = true) == true || 
                             body?.contains("Confirmed", ignoreCase = true) == true ||
                             body?.contains("Ksh", ignoreCase = true) == true

                if (isMpesa) {
                    println("Sync: Found M-Pesa message from $address")
                    messages.add(mapOf(
                        "body" to body,
                        "sender" to (address ?: "Unknown"),
                        "timestamp" to date
                    ))
                }
            }
        }
        println("Sync: Total M-Pesa messages found: ${messages.size}")
        return messages
    }
}

