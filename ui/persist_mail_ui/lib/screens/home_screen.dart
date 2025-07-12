import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../providers/theme_provider.dart';
import 'mailbox_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DomainSelectionTab(),
    const MailboxScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Mailbox'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DomainSelectionTab extends StatefulWidget {
  const DomainSelectionTab({super.key});

  @override
  State<DomainSelectionTab> createState() => _DomainSelectionTabState();
}

class _DomainSelectionTabState extends State<DomainSelectionTab> {
  String? _selectedDomain;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PersistMail'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: themeProvider.toggleTheme,
              );
            },
          ),
        ],
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.isLoading && emailProvider.domains.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (emailProvider.error != null && emailProvider.domains.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${emailProvider.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: emailProvider.fetchDomains,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Email',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (emailProvider.hasSelectedEmail) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  emailProvider.selectedEmail!,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () => _copyToClipboard(
                                  emailProvider.selectedEmail!,
                                ),
                                tooltip: 'Copy to clipboard',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: emailProvider.clearSelectedEmail,
                            child: const Text('Clear Email'),
                          ),
                        ] else ...[
                          Text(
                            'No email selected',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Available Domains',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: emailProvider.domains.isEmpty
                      ? const Center(child: Text('No domains available'))
                      : ListView.builder(
                          itemCount: emailProvider.domains.length,
                          itemBuilder: (context, index) {
                            final domain = emailProvider.domains[index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                  '@${domain.domain}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  domain.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: domain.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: domain.isActive
                                    ? () => _generateEmail(
                                        domain.domain,
                                        emailProvider,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
                if (emailProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateEmail(
    String domain,
    EmailProvider emailProvider,
  ) async {
    final email = await emailProvider.generateEmail(domain);
    if (email != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generated: $email'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () => _copyToClipboard(email),
          ),
        ),
      );
    }
  }

  void _copyToClipboard(String text) {
    // Note: You'll need to implement clipboard functionality
    // For now, just show a snackbar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied: $text')));
  }
}
