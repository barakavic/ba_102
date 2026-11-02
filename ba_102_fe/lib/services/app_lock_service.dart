import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class PinVerificationResult {
  const PinVerificationResult({required this.verified, this.cooldown});

  final bool verified;
  final Duration? cooldown;
}

class AppLockService {
  AppLockService({
    LocalAuthentication? authentication,
    FlutterSecureStorage? storage,
  }) : _authentication = authentication ?? LocalAuthentication(),
       _storage =
           storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(resetOnError: false),
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
               synchronizable: false,
             ),
           );

  static const _enabledKey = 'ba102.app_lock.enabled.v1';
  static const _pinSaltKey = 'ba102.app_lock.pin_salt.v1';
  static const _pinVerifierKey = 'ba102.app_lock.pin_verifier.v1';
  static const _pinFailuresKey = 'ba102.app_lock.pin_failures.v1';
  static const _pinCooldownUntilKey = 'ba102.app_lock.pin_cooldown_until.v1';
  static const pinLength = 4;
  static const _pbkdf2Iterations = 120000;

  final LocalAuthentication _authentication;
  final FlutterSecureStorage _storage;

  static bool get isPlatformSupported => Platform.isAndroid || Platform.isIOS;

  Future<bool> isEnabled() async =>
      await _storage.read(key: _enabledKey) == 'true';

  Future<bool> hasBiometricHardware() => _authentication.canCheckBiometrics;

  Future<bool> authenticateBiometric(String reason) async {
    try {
      return await _authentication.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: false,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> enableWithPin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltEncoded = base64UrlEncode(salt);
    final verifier = await _derivePinVerifier(pin, saltEncoded);
    await _storage.write(key: _enabledKey, value: 'false');
    await _storage.write(key: _pinSaltKey, value: saltEncoded);
    await _storage.write(key: _pinVerifierKey, value: verifier);
    await _resetPinFailures();
    await _storage.write(key: _enabledKey, value: 'true');
  }

  Future<void> resetPin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltEncoded = base64UrlEncode(salt);
    final verifier = await _derivePinVerifier(pin, saltEncoded);
    await _storage.write(key: _pinSaltKey, value: saltEncoded);
    await _storage.write(key: _pinVerifierKey, value: verifier);
    await _resetPinFailures();
  }

  Future<PinVerificationResult> verifyPin(String pin) async {
    final now = DateTime.now();
    final cooldownValue = await _storage.read(key: _pinCooldownUntilKey);
    final cooldownUntil = int.tryParse(cooldownValue ?? '');
    if (cooldownUntil != null && cooldownUntil > now.millisecondsSinceEpoch) {
      return PinVerificationResult(
        verified: false,
        cooldown: Duration(
          milliseconds: cooldownUntil - now.millisecondsSinceEpoch,
        ),
      );
    }

    final salt = await _storage.read(key: _pinSaltKey);
    final expected = await _storage.read(key: _pinVerifierKey);
    if (salt == null || expected == null) {
      return const PinVerificationResult(verified: false);
    }
    final actual = await _derivePinVerifier(pin, salt);
    if (_constantTimeEquals(actual, expected)) {
      await _resetPinFailures();
      return const PinVerificationResult(verified: true);
    }

    final failures =
        (int.tryParse(await _storage.read(key: _pinFailuresKey) ?? '') ?? 0) +
        1;
    await _storage.write(key: _pinFailuresKey, value: failures.toString());
    if (failures < 5 || failures % 5 != 0) {
      return const PinVerificationResult(verified: false);
    }
    final exponent = min((failures ~/ 5) - 1, 4);
    final cooldownSeconds = min(30 * (1 << exponent), 300);
    final until = now.add(Duration(seconds: cooldownSeconds));
    await _storage.write(
      key: _pinCooldownUntilKey,
      value: until.millisecondsSinceEpoch.toString(),
    );
    return PinVerificationResult(
      verified: false,
      cooldown: Duration(seconds: cooldownSeconds),
    );
  }

  Future<void> disable() async {
    await _storage.delete(key: _pinSaltKey);
    await _storage.delete(key: _pinVerifierKey);
    await _resetPinFailures();
    await _storage.write(key: _enabledKey, value: 'false');
  }

  Future<void> _resetPinFailures() async {
    await _storage.write(key: _pinFailuresKey, value: '0');
    await _storage.delete(key: _pinCooldownUntilKey);
  }

  Future<String> _derivePinVerifier(String pin, String encodedSalt) =>
      compute(_pbkdf2Sha256, <String, Object>{
        'pin': pin,
        'salt': base64Url.decode(encodedSalt),
        'iterations': _pbkdf2Iterations,
      });

  bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var i = 0; i < left.length; i++) {
      difference |= left.codeUnitAt(i) ^ right.codeUnitAt(i);
    }
    return difference == 0;
  }
}

String _pbkdf2Sha256(Map<String, Object> input) {
  final password = utf8.encode(input['pin']! as String);
  final salt = input['salt']! as List<int>;
  final iterations = input['iterations']! as int;
  final hmac = Hmac(sha256, password);
  final block = <int>[...salt, 0, 0, 0, 1];
  var u = hmac.convert(block).bytes;
  final derived = List<int>.from(u);
  for (var iteration = 1; iteration < iterations; iteration++) {
    u = hmac.convert(u).bytes;
    for (var i = 0; i < derived.length; i++) {
      derived[i] ^= u[i];
    }
  }
  return base64UrlEncode(derived);
}
