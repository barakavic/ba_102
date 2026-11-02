import 'package:ba_102_fe/services/app_lock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<String?> showPinSetupDialog(BuildContext context) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const _PinSetupDialog(),
);

Future<String?> showPinEntryDialog(
  BuildContext context, {
  String title = 'Enter your app PIN',
}) => showDialog<String>(
  context: context,
  builder: (_) => _PinEntryDialog(title: title),
);

class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create your app PIN'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Set a four-digit PIN to use if biometrics are unavailable.',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pinController,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppLockService.pinLength),
          ],
          decoration: const InputDecoration(labelText: 'Four-digit PIN'),
          onChanged: (_) => setState(() => _error = null),
        ),
        TextField(
          controller: _confirmController,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(AppLockService.pinLength),
          ],
          decoration: const InputDecoration(labelText: 'Confirm PIN'),
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final pin = _pinController.text;
          if (pin.length != AppLockService.pinLength) {
            setState(() => _error = 'Enter all four digits.');
          } else if (pin != _confirmController.text) {
            setState(() => _error = 'The PINs do not match.');
          } else {
            Navigator.pop(context, pin);
          }
        },
        child: const Text('Continue'),
      ),
    ],
  );
}

class _PinEntryDialog extends StatefulWidget {
  const _PinEntryDialog({required this.title});

  final String title;

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(AppLockService.pinLength),
      ],
      decoration: const InputDecoration(labelText: 'Four-digit PIN'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_controller.text.length == AppLockService.pinLength) {
            Navigator.pop(context, _controller.text);
          }
        },
        child: const Text('Verify'),
      ),
    ],
  );
}
