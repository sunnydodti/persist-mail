import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../models/email_model.dart';
import 'email_detail_screen.dart';

class ActiveMailboxPage extends StatefulWidget {
  const ActiveMailboxPage({super.key});

  @override
  State<ActiveMailboxPage> createState() => _ActiveMailboxPageState();
}

class _ActiveMailboxPageState extends State<ActiveMailboxPage> {
  @override
  void initState() {
    super.initState();
    // Start auto-refresh when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emailProvider = Provider.of<EmailProvider>(context, listen: false);
      if (emailProvider.hasSelectedEmail) {
        emailProvider.fetchEmails();
        emailProvider.startAutoRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Stop auto-refresh when navigating back
          final emailProvider = Provider.of<EmailProvider>(
            context,
            listen: false,
          );
          emailProvider.stopAutoRefresh();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Active Mailbox'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Stop auto-refresh before navigating back
              final emailProvider = Provider.of<EmailProvider>(
                context,
                listen: false,
              );
              emailProvider.stopAutoRefresh();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            Consumer<EmailProvider>(
              builder: (context, emailProvider, child) {
                return IconButton(
                  icon: emailProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed:
                      emailProvider.hasSelectedEmail && !emailProvider.isLoading
                      ? () {
                          emailProvider.refresh();
                        }
                      : null,
                  tooltip: 'Refresh emails',
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
                      'Go back to select a mailbox',
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
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
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

            return Column(
              children: [
                // Mailbox header with auto-refresh counter
                _buildMailboxHeader(emailProvider),
                // Email list
                Expanded(
                  child: emailProvider.emails.isEmpty
                      ? _buildEmptyState(emailProvider)
                      : _buildEmailList(emailProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMailboxHeader(EmailProvider emailProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                      'Monitoring Mailbox',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emailProvider.selectedEmail!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: emailProvider.selectedEmail!),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email copied to clipboard')),
                  );
                },
                tooltip: 'Copy email address',
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 24),
              // Auto-refresh counter
              Consumer<EmailProvider>(
                builder: (context, emailProvider, child) {
                  return Row(
                    children: [
                      Icon(
                        emailProvider.isAutoRefreshActive
                            ? Icons.autorenew
                            : Icons.pause_circle_outline,
                        size: 16,
                        color: emailProvider.isAutoRefreshActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        emailProvider.isAutoRefreshActive
                            ? 'Auto-refresh: ${emailProvider.autoRefreshCountdown}s'
                            : 'Auto-refresh stopped',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: emailProvider.isAutoRefreshActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(EmailProvider emailProvider) {
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

  Widget _buildEmailList(EmailProvider emailProvider) {
    return RefreshIndicator(
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
