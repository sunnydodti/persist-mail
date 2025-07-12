import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text(
                          'Switch between light and dark theme',
                        ),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) => themeProvider.setTheme(value),
                        secondary: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Storage Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Storage',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Clear Cached Emails'),
                        subtitle: const Text(
                          'Remove all stored emails from device',
                        ),
                        onTap: () => _showClearEmailsDialog(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.cleaning_services),
                        title: const Text('Clear All Data'),
                        subtitle: const Text(
                          'Remove all app data and preferences',
                        ),
                        onTap: () => _showClearAllDataDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // App Info Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('PersistMail'),
                        subtitle: Text(
                          'Version 1.0.0\nTemporary email service',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.code),
                        title: const Text('Developer Mode'),
                        subtitle: const Text('Current flavor: DEV'),
                        trailing: Chip(
                          label: const Text('DEV'),
                          backgroundColor: Colors.orange.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Future Features
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coming Soon',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      const ListTile(
                        leading: Icon(Icons.account_circle_outlined),
                        title: Text('User Accounts'),
                        subtitle: Text('Sign up for premium features'),
                        enabled: false,
                      ),
                      const ListTile(
                        leading: Icon(Icons.notifications_outlined),
                        title: Text('Push Notifications'),
                        subtitle: Text('Get notified of new emails'),
                        enabled: false,
                      ),
                      const ListTile(
                        leading: Icon(Icons.cloud_sync_outlined),
                        title: Text('Cloud Sync'),
                        subtitle: Text('Sync emails across devices'),
                        enabled: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearEmailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cached Emails'),
        content: const Text(
          'This will remove all cached emails from your device. '
          'You can still view emails by refreshing the mailbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearEmails();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cached emails cleared')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will remove all app data including emails, preferences, '
          'and selected email addresses. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.clearEmails();
              await StorageService.clearDomains();
              await StorageService.clearPreferences();
              await StorageService.clearAllSecureData();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
