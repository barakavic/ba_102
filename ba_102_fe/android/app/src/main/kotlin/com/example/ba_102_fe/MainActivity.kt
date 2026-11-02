package com.example.ba_102_fe

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Telephony
class MainActivity : FlutterFragmentActivity(){
    private val CHANNEL = "com.example.ba_102_fe/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine){
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        SmsReceiver.methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "fetchOldSms" -> {
                        val since = call.argument<Long>("since")
                        val until = call.argument<Long>("until")
                        result.success(fetchHistoricalSms(since, until))
                    }
                    "getEarliestMpesaSmsTimestamp" -> {
                        result.success(getEarliestMpesaSmsTimestamp())
                    }
                    else -> result.notImplemented()
                }
            } catch (error: SecurityException) {
                result.error(
                    "SMS_PERMISSION_DENIED",
                    "SMS permission is required to read message history.",
                    null
                )
            } catch (error: Exception) {
                result.error("SMS_HISTORY_READ_FAILED", error.message, null)
            }
        }
    }

    private fun fetchHistoricalSms(since: Long?, until: Long?): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val conditions = mutableListOf<String>()
        val arguments = mutableListOf<String>()
        if (since != null) {
            conditions.add("date >= ?")
            arguments.add(since.toString())
        }
        if (until != null) {
            conditions.add("date <= ?")
            arguments.add(until.toString())
        }
        val cursor = contentResolver.query(
            android.provider.Telephony.Sms.CONTENT_URI,
            arrayOf("body", "address", "date"),
            conditions.takeIf { it.isNotEmpty() }?.joinToString(" AND "),
            arguments.takeIf { it.isNotEmpty() }?.toTypedArray(),
            "date DESC"
        ) ?: throw IllegalStateException("Unable to query SMS history.")

        cursor.use {
            val bodyIdx = it.getColumnIndex("body")
            val addrIdx = it.getColumnIndex("address")
            val dateIdx = it.getColumnIndex("date")

            while (it.moveToNext()) {
                val address = it.getString(addrIdx)
                val body = it.getString(bodyIdx)
                val date = it.getLong(dateIdx)

                if (isMpesaMessage(address, body)) {
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

    private fun getEarliestMpesaSmsTimestamp(): Long? {
        val cursor = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf("body", "address", "date"),
            null,
            null,
            "date ASC"
        ) ?: throw IllegalStateException("Unable to query SMS history.")

        cursor.use {
            val bodyIdx = it.getColumnIndexOrThrow("body")
            val addrIdx = it.getColumnIndexOrThrow("address")
            val dateIdx = it.getColumnIndexOrThrow("date")

            while (it.moveToNext()) {
                val body = it.getString(bodyIdx)
                val address = it.getString(addrIdx)
                if (isMpesaMessage(address, body)) {
                    return it.getLong(dateIdx)
                }
            }
        }
        return null
    }

    private fun isMpesaMessage(address: String?, body: String?): Boolean {
        return address?.contains("MPESA", ignoreCase = true) == true ||
            address?.contains("M-PESA", ignoreCase = true) == true ||
            address?.contains("Safaricom", ignoreCase = true) == true ||
            body?.contains("MPESA", ignoreCase = true) == true ||
            body?.contains("M-PESA", ignoreCase = true) == true ||
            body?.contains("Confirmed", ignoreCase = true) == true ||
            body?.contains("Ksh", ignoreCase = true) == true
    }
}

