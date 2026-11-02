import 'dart:async';

import 'package:ba_102_fe/features/security/presentation/pin_dialogs.dart';
import 'package:ba_102_fe/services/app_lock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  final _service = AppLockService();
  final _pinController = TextEditingController();
  bool _ready = false;
  bool _locked = true;
  bool _pinMode = false;
  bool _busy = false;
  bool _startedInitialPrompt = false;
  String? _message;
  Duration? _cooldown;
  Timer? _cooldownTimer;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final enabled = await _service.isEnabled();
      if (!mounted) return;
      setState(() {
        _ready = true;
        _locked = enabled;
        _loadError = null;
      });
      if (enabled) _queueInitialBiometricPrompt();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _loadError = error;
        _locked = true;
      });
    }
  }

  void _queueInitialBiometricPrompt() {
    if (_startedInitialPrompt) return;
    _startedInitialPrompt = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _unlockWithBiometrics();
    });
  }

  Future<void> _unlockWithBiometrics() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final unlocked = await _service.authenticateBiometric(
      'Unlock your financial data',
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _locked = !unlocked;
      if (!unlocked) {
        _message =
            'Biometric verification was not completed. Try again or use your app PIN.';
      }
    });
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text;
    if (pin.length != AppLockService.pinLength || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    late final PinVerificationResult result;
    try {
      result = await _service.verifyPin(pin);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Could not verify the app PIN. Please try again.';
      });
      return;
    }
    if (!mounted) return;
    _pinController.clear();
    setState(() {
      _busy = false;
      _locked = !result.verified;
      _cooldown = result.cooldown;
      _message = result.verified
          ? null
          : result.cooldown == null
          ? 'That PIN is incorrect.'
          : 'Too many attempts. Try again in ${result.cooldown!.inSeconds.ceil()} seconds.';
    });
    if (result.cooldown != null) _startCooldownTimer(result.cooldown!);
  }

  void _startCooldownTimer(Duration duration) {
    _cooldownTimer?.cancel();
    var seconds = duration.inSeconds.ceil();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      seconds--;
      if (seconds <= 0) {
        timer.cancel();
        setState(() {
          _cooldown = null;
          _message = null;
        });
      } else {
        setState(() {
          _cooldown = Duration(seconds: seconds);
          _message = 'Too many attempts. Try again in $seconds seconds.';
        });
      }
    });
  }

  Future<void> _resetForgottenPin() async {
    if (_busy) return;
    setState(() => _busy = true);
    final verified = await _service.authenticateBiometric(
      'Verify your identity to reset your app PIN',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!verified) {
      setState(
        () => _message = 'Biometric verification is required to reset the PIN.',
      );
      return;
    }
    final pin = await showPinSetupDialog(context);
    if (!mounted || pin == null) return;
    try {
      await _service.resetPin(pin);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Could not save the new app PIN. Try again.');
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _locked = false;
      _pinMode = false;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return _gateScaffold(const Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return _gateScaffold(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 44),
                const SizedBox(height: 12),
                const Text('Could not verify the app lock setting.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _initialize,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_locked) return widget.child;
    return _gateScaffold(
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_person_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unlock Spree',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verify your identity to view your financial information.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_pinMode) ...[
                  TextField(
                    controller: _pinController,
                    autofocus: true,
                    obscureText: true,
                    enabled: !_busy && _cooldown == null,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: AppLockService.pinLength,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        AppLockService.pinLength,
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Four-digit app PIN',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.length == AppLockService.pinLength) {
                        _unlockWithPin();
                      }
                    },
                    onSubmitted: (_) => _unlockWithPin(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy || _cooldown != null
                        ? null
                        : _unlockWithPin,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock with PIN'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _unlockWithBiometrics,
                    child: const Text('Use biometrics instead'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _resetForgottenPin,
                    child: const Text('Forgot PIN?'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: _busy ? null : _unlockWithBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(
                      _busy ? 'Verifying…' : 'Verify with biometrics',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _pinMode = true;
                            _message = null;
                          }),
                    child: const Text('Use PIN instead'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _resetForgottenPin,
                    child: const Text('Forgot PIN?'),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gateScaffold(Widget body) => Scaffold(body: SafeArea(child: body));
}
