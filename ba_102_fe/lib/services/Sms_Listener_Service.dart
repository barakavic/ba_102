import 'package:ba_102_fe/utils/app_logger.dart';
import "package:flutter/services.dart";
import "package:permission_handler/permission_handler.dart";

class SmsListenerService {
  static const platform = MethodChannel('com.example.ba_102_fe/sms');

  final Function(Map<String, dynamic>) onMessageReceived;

  SmsListenerService({required this.onMessageReceived});

  // Initialize Listener
  Future<void> initialize() async {
    final status = await Permission.sms.request();

    if (status.isGranted) {
      platform.setMethodCallHandler(_handleMethodCall);
      AppLogger.i("SMS Listener initialized");
    } else {
      AppLogger.w("SMS Permission denied");
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onSmsReceived') {
      final Map<String, dynamic> smsData = Map<String, dynamic>.from(
        call.arguments,
      );
      onMessageReceived(smsData);
    }
  }

  Future<List<Map<String, dynamic>>> fetchHistoricalMessages({
    DateTime? since,
    DateTime? until,
  }) async {
    try {
      await _ensureSmsPermission();
      final int? sinceTimestamp = since?.millisecondsSinceEpoch;
      final int? untilTimestamp = until?.millisecondsSinceEpoch;
      final List<dynamic> result = await platform.invokeMethod('fetchOldSms', {
        'since': sinceTimestamp,
        'until': untilTimestamp,
      });
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } on PlatformException catch (e) {
      AppLogger.e("Failed to fetch historical SMS: ${e.message}");
      rethrow;
    }
  }

  Future<DateTime?> getEarliestMpesaMessageDate() async {
    try {
      await _ensureSmsPermission();
      final timestamp = await platform.invokeMethod<int>(
        'getEarliestMpesaSmsTimestamp',
      );
      return timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(timestamp);
    } on PlatformException catch (e) {
      AppLogger.e("Failed to find earliest M-Pesa SMS: ${e.message}");
      rethrow;
    }
  }

  Future<void> _ensureSmsPermission() async {
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      throw PlatformException(
        code: 'SMS_PERMISSION_DENIED',
        message: 'SMS permission is required to read message history.',
      );
    }
  }

  void dispose() {
    platform.setMethodCallHandler(null);
  }
}
