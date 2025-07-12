import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/email_provider.dart';
import '../models/email_model.dart';

class EmailDetailScreen extends StatefulWidget {
  final String emailId;

  const EmailDetailScreen({super.key, required this.emailId});

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  EmailModel? _email;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmailContent();
  }

  Future<void> _loadEmailContent() async {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);

    try {
      final email = await emailProvider.getEmailContent(widget.emailId);
      if (mounted) {
        setState(() {
          _email = email;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email'),
        actions: [
          if (_email != null) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyEmailContent(),
              tooltip: 'Copy email content',
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy_sender',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Copy Sender'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_subject',
                  child: ListTile(
                    leading: Icon(Icons.subject),
                    title: Text('Copy Subject'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy_all',
                  child: ListTile(
                    leading: Icon(Icons.content_copy),
                    title: Text('Copy All'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading email',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmailContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_email == null) {
      return const Center(child: Text('Email not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject
                  Text(
                    _email!.subject.isNotEmpty
                        ? _email!.subject
                        : '(No subject)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // From
                  _buildInfoRow(
                    'From',
                    _email!.from,
                    Icons.person,
                    onTap: () =>
                        _copyToClipboard(_email!.from, 'Sender copied'),
                  ),
                  const SizedBox(height: 8),

                  // To
                  _buildInfoRow(
                    'To',
                    _email!.to,
                    Icons.email,
                    onTap: () =>
                        _copyToClipboard(_email!.to, 'Recipient copied'),
                  ),
                  const SizedBox(height: 8),

                  // Received Date
                  _buildInfoRow(
                    'Received',
                    _formatDateTime(_email!.receivedAt),
                    Icons.schedule,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Email Body Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.message),
                      const SizedBox(width: 8),
                      Text(
                        'Message',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: SelectableText(
                      _email!.body.isNotEmpty ? _email!.body : '(No content)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HTML Body if available
          if (_email!.htmlBody != null && _email!.htmlBody!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.code),
                        const SizedBox(width: 8),
                        Text(
                          'HTML Content',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: SelectableText(
                        _email!.htmlBody!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: value.contains('@') ? 'monospace' : null,
                ),
              ),
            ),
            if (onTap != null) ...[
              Icon(
                Icons.content_copy,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleMenuAction(String action) {
    if (_email == null) return;

    switch (action) {
      case 'copy_sender':
        _copyToClipboard(_email!.from, 'Sender copied');
        break;
      case 'copy_subject':
        _copyToClipboard(_email!.subject, 'Subject copied');
        break;
      case 'copy_all':
        _copyEmailContent();
        break;
    }
  }

  void _copyEmailContent() {
    if (_email == null) return;

    final content =
        '''
Subject: ${_email!.subject}
From: ${_email!.from}
To: ${_email!.to}
Date: ${_formatDateTime(_email!.receivedAt)}

${_email!.body}
''';

    _copyToClipboard(content, 'Email content copied');
  }

  void _copyToClipboard(String text, String message) {
    // Note: You'll need to implement actual clipboard functionality
    // For now, just show a snackbar
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
