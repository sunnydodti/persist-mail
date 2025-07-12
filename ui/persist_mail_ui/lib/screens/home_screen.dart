import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../providers/theme_provider.dart';
import '../services/snackbar_service.dart';
import '../services/logging_service.dart';
import '../models/mailbox_history.dart';
import 'active_mailbox_page.dart';
import 'mailbox_history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const MailboxHistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _customUsernameController =
      TextEditingController();
  String? _selectedDomain;
  bool _isGenerating = false;

  // Sample suggested usernames
  final List<String> _suggestedUsernames = [
    'tempuser',
    'quickmail',
    'fastuser',
    'mailbox',
    'inbox',
    'tempbox',
    'fastmail',
    'testuser',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emailProvider = Provider.of<EmailProvider>(context, listen: false);
      // Set selected domain from provider if available, or use first domain
      if (emailProvider.selectedDomain != null &&
          emailProvider.domains.any(
            (d) => d.domain == emailProvider.selectedDomain,
          )) {
        setState(() {
          _selectedDomain = emailProvider.selectedDomain;
        });
      } else if (emailProvider.domains.isNotEmpty && _selectedDomain == null) {
        setState(() {
          _selectedDomain = emailProvider.domains.first.domain;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emailProvider = Provider.of<EmailProvider>(context, listen: false);
      // Validate and update selected domain if needed
      if (_selectedDomain != null &&
          !emailProvider.domains.any((d) => d.domain == _selectedDomain)) {
        setState(() {
          _selectedDomain = emailProvider.domains.isNotEmpty
              ? emailProvider.domains.first.domain
              : null;
        });
      }
    });
  }

  @override
  void dispose() {
    _customUsernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PersistMail'),
        centerTitle: true,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: themeProvider.toggleTheme,
                tooltip: 'Toggle theme',
              );
            },
          ),
        ],
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.isLoading && emailProvider.domains.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading domains...'),
                ],
              ),
            );
          }

          if (emailProvider.error != null && emailProvider.domains.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading domains',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emailProvider.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: emailProvider.fetchDomains,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Previous Mailboxes Section
                if (emailProvider.mailboxHistory.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Previous Mailboxes',
                    onViewAll: emailProvider.mailboxHistory.length > 6
                        ? () => _showAllMailboxHistoryDialog(emailProvider)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _buildMailboxHistoryGrid(emailProvider),
                  const SizedBox(height: 24),
                ],

                // Current Mailbox Section
                if (emailProvider.selectedEmail != null) ...[
                  _buildSectionHeader('Current Mailbox'),
                  const SizedBox(height: 8),
                  _buildCurrentMailboxCard(emailProvider),
                  const SizedBox(height: 24),
                ],

                // Domain Selection
                _buildSectionHeader('Select Domain'),
                const SizedBox(height: 8),
                _buildDomainDropdown(emailProvider),
                const SizedBox(height: 24),

                // Email Generation Options
                _buildSectionHeader('Select Mailbox'),
                const SizedBox(height: 8),
                _buildEmailGenerationOptions(emailProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }

  Widget _buildMailboxHistoryGrid(EmailProvider emailProvider) {
    final historyToShow = emailProvider.mailboxHistory.take(6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3,
      ),
      itemCount: historyToShow.length,
      itemBuilder: (context, index) {
        final history = historyToShow[index];
        return _buildMailboxHistoryCard(history, emailProvider);
      },
    );
  }

  Widget _buildMailboxHistoryCard(
    MailboxHistory history,
    EmailProvider emailProvider,
  ) {
    final isSelected = emailProvider.selectedEmail == history.email;

    return Card(
      elevation: isSelected ? 3 : 1,
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () => _selectPreviousMailbox(history, emailProvider),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                history.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimeAgo(history.lastUsed),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMailboxCard(EmailProvider emailProvider) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: () {
          // Navigate to Active Mailbox Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActiveMailboxPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mail,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      emailProvider.selectedEmail!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        _copyToClipboard(emailProvider.selectedEmail!),
                    icon: Icon(
                      Icons.copy,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    tooltip: 'Copy email',
                  ),
                  IconButton(
                    onPressed: emailProvider.refresh,
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    tooltip: 'Refresh emails',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${emailProvider.emails.length} emails',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  if (emailProvider.isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainDropdown(EmailProvider emailProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a domain for your email',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value:
                  emailProvider.domains.any((d) => d.domain == _selectedDomain)
                  ? _selectedDomain
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: emailProvider.domains.map((domain) {
                return DropdownMenuItem<String>(
                  value: domain.domain,
                  child: Text(
                    '@${domain.domain}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDomain = value;
                });
                AppLogger.userAction(
                  'Domain Selected',
                  context: {'domain': value},
                );
              },
              hint: const Text('Select a domain'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailGenerationOptions(EmailProvider emailProvider) {
    return Column(
      children: [
        // Random Email Generation
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shuffle),
                    const SizedBox(width: 8),
                    Text(
                      'Select Random Mailbox',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Quickly select a random temporary email mailbox',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedDomain != null && !_isGenerating
                        ? () => _selectRandomMailbox(emailProvider)
                        : null,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _isGenerating ? 'Selecting...' : 'Select Random',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Custom Username
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 8),
                    Text(
                      'Custom Username',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an email with your preferred username',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customUsernameController,
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter username',
                          border: const OutlineInputBorder(),
                          // helper: _getCustomUsernameHelperText(_selectedDomain),
                          helperText: _getCustomUsernameHelperText(
                            _selectedDomain,
                          ),
                        ),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          _selectedDomain != null &&
                              _customUsernameController.text.isNotEmpty &&
                              _customUsernameController.text.length >= 3 &&
                              !_isGenerating
                          ? () => _selectCustomMailbox(emailProvider)
                          : null,
                      child: _isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Suggested Usernames
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline),
                    const SizedBox(width: 8),
                    Text(
                      'Suggested Usernames',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Quick suggestions for common temporary email names',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedUsernames.map((username) {
                    return ActionChip(
                      label: Text(username),
                      onPressed: _selectedDomain != null && !_isGenerating
                          ? () =>
                                _selectSuggestedMailbox(emailProvider, username)
                          : null,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _selectPreviousMailbox(
    MailboxHistory history,
    EmailProvider emailProvider,
  ) {
    emailProvider.selectEmail(history.email, history.domain);
    SnackbarService.showSuccess('Selected: ${history.email}');
    AppLogger.userAction(
      'Previous Mailbox Selected',
      context: {'email': history.email, 'domain': history.domain},
    );

    // Navigate to Active Mailbox Page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActiveMailboxPage()),
    );
  }

  void _showAllMailboxHistoryDialog(EmailProvider emailProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Previous Mailboxes'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: emailProvider.mailboxHistory.length,
            itemBuilder: (context, index) {
              final history = emailProvider.mailboxHistory[index];
              return ListTile(
                title: Text(
                  history.email,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                subtitle: Text(_formatTimeAgo(history.lastUsed)),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(history.email),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _selectPreviousMailbox(history, emailProvider);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _selectRandomMailbox(EmailProvider emailProvider) async {
    if (_selectedDomain == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Create a random username
      final randomUsername =
          _suggestedUsernames[DateTime.now().millisecondsSinceEpoch %
              _suggestedUsernames.length] +
          DateTime.now().millisecondsSinceEpoch.toString().substring(8);

      final email = await emailProvider.selectMailbox(
        randomUsername,
        _selectedDomain!,
      );
      if (email != null && mounted) {
        SnackbarService.showSuccess('Selected mailbox: $email');
        AppLogger.userAction(
          'Random Mailbox Selected',
          context: {'email': email, 'domain': _selectedDomain},
        );

        // Navigate to Active Mailbox Page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActiveMailboxPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError('Failed to select mailbox: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _selectCustomMailbox(EmailProvider emailProvider) async {
    if (_selectedDomain == null || _customUsernameController.text.isEmpty)
      return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final username = _customUsernameController.text.trim();
      final email = await emailProvider.selectMailbox(
        username,
        _selectedDomain!,
      );

      if (email != null && mounted) {
        SnackbarService.showSuccess('Selected mailbox: $email');
        _customUsernameController.clear();
        AppLogger.userAction(
          'Custom Mailbox Selected',
          context: {
            'username': username,
            'email': email,
            'domain': _selectedDomain,
          },
        );

        // Navigate to Active Mailbox Page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActiveMailboxPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError('Failed to select mailbox: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _selectSuggestedMailbox(
    EmailProvider emailProvider,
    String username,
  ) async {
    if (_selectedDomain == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final email = await emailProvider.selectMailbox(
        username,
        _selectedDomain!,
      );

      if (email != null && mounted) {
        SnackbarService.showSuccess('Selected mailbox: $email');
        AppLogger.userAction(
          'Suggested Mailbox Selected',
          context: {
            'username': username,
            'email': email,
            'domain': _selectedDomain,
          },
        );

        // Navigate to Active Mailbox Page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActiveMailboxPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError('Failed to select mailbox: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    SnackbarService.showSuccess('Copied to clipboard: $text');
    AppLogger.userAction('Email Copied', context: {'email': text});
  }

  // Widget _getCustomUsernameHelperText(String? selectedDomain) {
  //   if (selectedDomain == null) {
  //     return const SizedBox.shrink();
  //   }
  //   String text = (_customUsernameController.text.isNotEmpty)
  //       ? '${_customUsernameController.text.trim()}@$selectedDomain'
  //       : '<username>@$selectedDomain';
  //   return Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey));
  // }

  String _getCustomUsernameHelperText(String? selectedDomain) {
    if (selectedDomain == null) {
      return '';
    }
    String text = (_customUsernameController.text.isNotEmpty)
        ? '${_customUsernameController.text.trim()}@$selectedDomain'
        : '<username>@$selectedDomain';
    return text;
  }
}
