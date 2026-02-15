import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/providers/theme_provider.dart';

// Provider to manage the global cloud sync setting
final cloudSyncProvider = StateProvider<bool>((ref) => true);

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncEnabled = ref.watch(cloudSyncProvider);
    final themeMode = ref.watch(themeProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

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
            activeColor: primaryColor,
            onChanged: (value) {
              ref.read(themeProvider.notifier).state =
                  value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          const Divider(),
          _buildSectionHeader('Data & Cloud'),
          SwitchListTile(
            secondary: Icon(Icons.cloud_sync_outlined, color: primaryColor),
            title: const Text('Cloud Synchronization'),
            subtitle: const Text('Backup transactions to your PostgreSQL cloud'),
            value: isSyncEnabled,
            activeColor: primaryColor,
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
          ListTile(
            leading: Icon(Icons.fingerprint, color: primaryColor),
            title: const Text('Biometric Lock'),
            subtitle: const Text('Secure your financial data'),
            trailing: Switch(value: false, onChanged: (v) {}),
          ),
          const Divider(),
          _buildSectionHeader('About'),
          ListTile(
            leading: Icon(Icons.info_outline, color: primaryColor),
            title: const Text('Version'),
            subtitle: const Text('1.7.0+9 "Sync Engine"'),
          ),
        ],
      ),
    );
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
}
