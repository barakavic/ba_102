import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/providers/theme_provider.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/database_encryption_service.dart';
import 'package:ba_102_fe/features/security/presentation/pin_dialogs.dart';
import 'package:ba_102_fe/services/app_lock_service.dart';

// Provider to manage the global cloud sync setting
final cloudSyncProvider = StateProvider<bool>((ref) => true);
final databaseEncryptionConfirmationProvider = FutureProvider<String>(
  (ref) => DatabaseHelper.instance.getEncryptionConfirmationCode(),
);

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncEnabled = ref.watch(cloudSyncProvider);
    final themeMode = ref.watch(themeProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final databaseEncryption = ref.watch(
      databaseEncryptionConfirmationProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            secondary: Icon(
              themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
              color: primaryColor,
            ),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between light and dark themes'),
            value: themeMode == ThemeMode.dark,
            activeThumbColor: primaryColor,
            onChanged: (value) {
              ref.read(themeProvider.notifier).state = value
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),
          const Divider(),
          _buildSectionHeader('Data & Cloud'),
          SwitchListTile(
            secondary: Icon(Icons.cloud_sync_outlined, color: primaryColor),
            title: const Text('Cloud Synchronization'),
            subtitle: const Text(
              'Backup transactions to your PostgreSQL cloud',
            ),
            value: isSyncEnabled,
            activeThumbColor: primaryColor,
            onChanged: (value) {
              ref.read(cloudSyncProvider.notifier).state = value;
            },
          ),
          ListTile(
            enabled: false,
            leading: const Icon(Icons.timer_outlined, color: Colors.grey),
            title: const Text('Sync Frequency'),
            subtitle: const Text('Real-time (Coming Soon)'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionHeader('Security'),
          const _BiometricLockTile(),
          const Divider(),
          _buildSectionHeader('About'),
          ListTile(
            leading: Icon(Icons.info_outline, color: primaryColor),
            title: const Text('Version'),
            subtitle: const Text('1.10.0+12 "Shopping & Budget Intelligence"'),
          ),
          ListTile(
            leading: Icon(
              databaseEncryption.hasValue
                  ? Icons.verified_user_outlined
                  : databaseEncryption.hasError
                  ? Icons.error_outline
                  : Icons.lock_outline,
              color: databaseEncryption.hasError
                  ? Theme.of(context).colorScheme.error
                  : primaryColor,
            ),
            title: const Text('Database encryption'),
            subtitle: databaseEncryption.when(
              data: Text.new,
              loading: () => const Text('Verifying encrypted database…'),
              error: (error, _) => Text(
                error is DatabaseEncryptionException
                    ? error.message
                    : 'Unable to verify database encryption.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _BiometricLockTile extends StatefulWidget {
  const _BiometricLockTile();

  @override
  State<_BiometricLockTile> createState() => _BiometricLockTileState();
}

class _BiometricLockTileState extends State<_BiometricLockTile> {
  final _service = AppLockService();
  bool _enabled = false;
  bool _loading = true;
  bool _busy = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _readSetting();
  }

  Future<void> _readSetting() async {
    try {
      final enabled = await _service.isEnabled();
      if (mounted) setState(() => _enabled = enabled);
    } catch (_) {
      _loadFailed = true;
      if (mounted) _showMessage('Could not read the biometric lock setting.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeSetting(bool enable) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (enable) {
        final hasHardware = await _service.hasBiometricHardware();
        if (!mounted) return;
        if (!hasHardware) {
          _showMessage(
            'This device does not support biometric authentication.',
          );
          return;
        }
        final pin = await showPinSetupDialog(context);
        if (!mounted || pin == null) return;
        final verified = await _service.authenticateBiometric(
          'Verify your identity to enable the app lock',
        );
        if (!verified) {
          if (mounted) {
            _showMessage(
              'Set up a fingerprint or face on this device, then try again.',
            );
          }
          return;
        }
        await _service.enableWithPin(pin);
        if (mounted) setState(() => _enabled = true);
      } else {
        var authorized = await _service.authenticateBiometric(
          'Verify your identity to disable the app lock',
        );
        if (!mounted) return;
        if (!authorized && mounted) {
          final pin = await showPinEntryDialog(
            context,
            title: 'Enter your app PIN to disable the lock',
          );
          if (pin != null) {
            final result = await _service.verifyPin(pin);
            authorized = result.verified;
            if (!authorized && mounted) {
              _showMessage(
                result.cooldown == null
                    ? 'That PIN is incorrect.'
                    : 'Too many attempts. Wait ${result.cooldown!.inSeconds.ceil()} seconds and try again.',
              );
            }
          }
        }
        if (!authorized || !mounted) return;
        await _service.disable();
        if (mounted) setState(() => _enabled = false);
      }
    } catch (error) {
      if (mounted) _showMessage('Could not update the app lock: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final supported = AppLockService.isPlatformSupported;
    final primary = Theme.of(context).colorScheme.primary;
    if (_loadFailed) {
      return ListTile(
        leading: Icon(Icons.fingerprint, color: primary),
        title: const Text('Biometric Lock'),
        subtitle: const Text('Could not read lock status'),
        trailing: IconButton(
          tooltip: 'Retry',
          onPressed: () {
            setState(() {
              _loading = true;
              _loadFailed = false;
            });
            _readSetting();
          },
          icon: const Icon(Icons.refresh),
        ),
      );
    }
    return SwitchListTile(
      secondary: Icon(Icons.fingerprint, color: primary),
      title: const Text('Biometric Lock'),
      subtitle: Text(
        !supported
            ? 'Unavailable on this platform'
            : _loading
            ? 'Checking lock status…'
            : 'Fingerprint or face, with a four-digit app PIN backup',
      ),
      value: _enabled,
      onChanged: !supported || _loading || _busy ? null : _changeSetting,
    );
  }
}
