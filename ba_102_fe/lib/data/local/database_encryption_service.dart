import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseEncryptionException implements Exception {
  const DatabaseEncryptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DatabaseEncryptionService {
  DatabaseEncryptionService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(resetOnError: false),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );

  static const _storageKey = 'ba102.database.encryption_key.v1';
  final FlutterSecureStorage _storage;

  Future<String?> readKey() => _storage.read(key: _storageKey);

  Future<String> createAndStoreKey() async {
    final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final key = base64UrlEncode(bytes);
    await _storage.write(key: _storageKey, value: key);
    return key;
  }
}
