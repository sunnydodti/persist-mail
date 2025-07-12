import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../models/mailbox_history.dart';
import '../services/snackbar_service.dart';
import '../services/logging_service.dart';
import 'mailbox_screen.dart';

class MailboxHistoryScreen extends StatelessWidget {
  const MailboxHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mailbox History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          if (emailProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (emailProvider.mailboxHistory.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No mailbox history',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a mailbox from the home page to see it here',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Mailboxes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${emailProvider.mailboxHistory.length} mailboxes used',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (emailProvider.selectedEmail != null) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Current Mailbox',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              emailProvider.selectedEmail!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () => _copyToClipboard(
                              emailProvider.selectedEmail!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Mailbox list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: emailProvider.mailboxHistory.length,
                  itemBuilder: (context, index) {
                    final mailbox = emailProvider.mailboxHistory[index];
                    return _buildMailboxCard(context, mailbox, emailProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMailboxCard(
    BuildContext context,
    MailboxHistory mailbox,
    EmailProvider emailProvider,
  ) {
    final isCurrentlySelected = emailProvider.selectedEmail == mailbox.email;
    final emailCount = emailProvider.getEmailsForMailbox(mailbox.email).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCurrentlySelected ? 3 : 1,
      color: isCurrentlySelected 
          ? Theme.of(context).colorScheme.primaryContainer 
          : null,
      child: InkWell(
        onTap: () => _selectMailbox(context, mailbox, emailProvider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mailbox.email,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCurrentlySelected 
                                    ? Theme.of(context).colorScheme.primary 
                                    : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Domain: ${mailbox.domain}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(width: 16),
                            if (emailCount > 0) ...[
                              Icon(
                                Icons.email,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$emailCount cached emails',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ] else
                              Text(
                                'No cached emails',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'copy':
                          _copyToClipboard(mailbox.email);
                          break;
                        case 'select':
                          _selectMailbox(context, mailbox, emailProvider);
                          break;
                        case 'view_emails':
                          _viewMailboxEmails(context, mailbox, emailProvider);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            const Icon(Icons.copy, size: 18),
                            const SizedBox(width: 8),
                            const Text('Copy Email'),
                          ],
                        ),
                      ),
                      if (!isCurrentlySelected)
                        PopupMenuItem(
                          value: 'select',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 18),
                              const SizedBox(width: 8),
                              const Text('Select Mailbox'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'view_emails',
                        child: Row(
                          children: [
                            const Icon(Icons.email, size: 18),
                            const SizedBox(width: 8),
                            const Text('View Emails'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last used: ${_formatTimeAgo(mailbox.lastUsed)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatTimeAgo(mailbox.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              if (isCurrentlySelected) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Current',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _selectMailbox(
    BuildContext context,
    MailboxHistory mailbox,
    EmailProvider emailProvider,
  ) {
    emailProvider.selectEmail(mailbox.email, mailbox.domain);
    SnackbarService.showSuccess('Selected: ${mailbox.email}');
    AppLogger.userAction('Mailbox Selected from History', context: {
      'email': mailbox.email,
      'domain': mailbox.domain,
    });
  }

  void _viewMailboxEmails(
    BuildContext context,
    MailboxHistory mailbox,
    EmailProvider emailProvider,
  ) {
    // First select the mailbox
    emailProvider.selectEmail(mailbox.email, mailbox.domain);
    
    // Then navigate to mailbox screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MailboxScreen()),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    SnackbarService.showSuccess('Copied to clipboard: $text');
    AppLogger.userAction('Email Copied from History', context: {'email': text});
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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Mailbox History'),
        content: const Text(
          'This page shows all the temporary mailboxes you have used. '
          'Emails are automatically deleted after a certain period, but you can still '
          'view cached emails here even after they expire.\n\n'
          'Tap on any mailbox to select it and view its emails.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
