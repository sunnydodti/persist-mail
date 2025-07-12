import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../models/email_model.dart';
import 'email_detail_screen.dart';

class MailboxScreen extends StatelessWidget {
  const MailboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mailbox'),
        actions: [
          Consumer<EmailProvider>(
            builder: (context, emailProvider, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: emailProvider.hasSelectedEmail
                    ? emailProvider.refresh
                    : null,
              );
            },
          ),
        ],
      ),
      body: Consumer<EmailProvider>(
        builder: (context, emailProvider, child) {
          if (!emailProvider.hasSelectedEmail) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No mailbox selected',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Go to Home to select a mailbox',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (emailProvider.isLoading && emailProvider.emails.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (emailProvider.error != null && emailProvider.emails.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${emailProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: emailProvider.fetchEmails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (emailProvider.emails.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No emails yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    emailProvider.isLoading 
                        ? 'Loading emails...'
                        : 'Emails will appear here when received',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (!emailProvider.isLoading) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: emailProvider.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check for emails'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              // Current email address
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
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
                                'Monitoring:',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                emailProvider.selectedEmail!,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: emailProvider.selectedEmail!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email copied to clipboard')),
                            );
                          },
                          tooltip: 'Copy email address',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${emailProvider.emails.length} emails',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (emailProvider.isLoading) ...[
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Refreshing...',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Email list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: emailProvider.refresh,
                  child: ListView.builder(
                    itemCount: emailProvider.emails.length,
                    itemBuilder: (context, index) {
                      final email = emailProvider.emails[index];
                      return EmailListItem(
                        email: email,
                        onTap: () => _openEmailDetail(context, email),
                      );
                    },
                  ),
                ),
              ),
              // Loading indicator
              if (emailProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openEmailDetail(BuildContext context, EmailModel email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailDetailScreen(emailId: email.id),
      ),
    );
  }
}

class EmailListItem extends StatelessWidget {
  final EmailModel email;
  final VoidCallback onTap;

  const EmailListItem({super.key, required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            email.from.isNotEmpty ? email.from[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          email.subject.isNotEmpty ? email.subject : '(No subject)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: email.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email.from,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
            Text(
              email.body.isNotEmpty ? email.body : '(No content)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDateTime(email.receivedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!email.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
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
}
