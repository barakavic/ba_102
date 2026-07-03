import 'package:flutter/foundation.dart';

class AppLogger {
  static void i(String message) {
    if (kDebugMode) {
      debugPrint('INFO: $message');
    }
  }

  static void d(String message) {
    if (kDebugMode) {
      debugPrint('DEBUG: $message');
    }
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('ERROR: $message');
      if (error != null) debugPrint('Error details: $error');
      if (stackTrace != null) debugPrint('Stack trace:\n$stackTrace');
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      debugPrint('WARNING: $message');
    }
  }
}
