import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/email_model.dart';
import '../models/domain_model.dart';
import '../models/user_preferences.dart';
import '../models/mailbox_history.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/logging_service.dart';

class EmailProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  List<EmailModel> _emails = [];
  List<DomainModel> _domains = [];
  List<MailboxHistory> _mailboxHistory = [];
  String? _selectedEmail;
  String? _selectedDomain;
  bool _isLoading = false;
  String? _error;

  // Auto-refresh logic
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  DateTime? _refreshStartTime;
  int _currentRefreshInterval = AppConfig.initialRefreshInterval;

  // Auto-refresh state tracking
  int _autoRefreshCountdown = 0;
  bool _isAutoRefreshActive = false;
  int _consecutiveFailures = 0;

  // Getters
  List<EmailModel> get emails => _emails;
  List<DomainModel> get domains => _domains;
  List<MailboxHistory> get mailboxHistory => _mailboxHistory;
  String? get selectedEmail => _selectedEmail;
  String? get selectedDomain => _selectedDomain;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSelectedEmail => _selectedEmail != null;
  bool get hasMailboxHistory => _mailboxHistory.isNotEmpty;

  // Getters for auto-refresh state
  int get autoRefreshCountdown => _autoRefreshCountdown;
  bool get isAutoRefreshActive => _isAutoRefreshActive;
  int get consecutiveFailures => _consecutiveFailures;

  EmailProvider() {
    _initializeProvider();
    _startPeriodicCleanup();
  }

  Future<void> _initializeProvider() async {
    try {
      AppLogger.debug('EmailProvider: Starting initialization');

      // Load cached domains and mailbox history
      _domains = StorageService.getCachedDomains();
      _mailboxHistory = StorageService.getCachedMailboxHistories();

      // Load user preferences
      final prefs = StorageService.getUserPreferences();
      _selectedEmail = prefs.selectedEmail;
      _selectedDomain = prefs.selectedDomain;

      // Load cached emails for the selected mailbox only
      if (_selectedEmail != null) {
        _emails = StorageService.getCachedEmailsForMailbox(_selectedEmail!);
      }

      notifyListeners();

      // Fetch fresh data
      await fetchDomains();

      // Validate selected domain against available domains
      if (_selectedDomain != null &&
          !_domains.any((domain) => domain.domain == _selectedDomain)) {
        _selectedDomain = _domains.isNotEmpty ? _domains.first.domain : null;
        await _savePreferences();
      }

      if (_selectedEmail != null) {
        await fetchEmails();
        _startAutoRefresh();
      }

      AppLogger.info('EmailProvider: Initialization completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('EmailProvider: Failed to initialize', e, stackTrace);
      _setError('Failed to initialize: ${e.toString()}');
    }
  }

  // Fetch available domains
  Future<void> fetchDomains() async {
    final stopwatch = Stopwatch()..start();
    try {
      AppLogger.debug('EmailProvider: Fetching domains');
      _setLoading(true);
      final domains = await _apiService.getDomains();
      _domains = domains;
      await StorageService.saveDomains(domains);

      // Validate selected domain against available domains
      _validateSelectedDomain();

      AppLogger.info('EmailProvider: Domains fetched successfully', {
        'count': domains.length,
        'duration': '${stopwatch.elapsedMilliseconds}ms',
      });
      _clearError();
    } catch (e, stackTrace) {
      AppLogger.error('EmailProvider: Failed to fetch domains', e, stackTrace);
      _setError(e.toString());
    } finally {
      stopwatch.stop();
      _setLoading(false);
    }
  }

  // Select existing email
  Future<void> selectEmail(String email, String domain) async {
    _selectedEmail = email;
    _selectedDomain = domain;

    // Clear current emails and load cached emails for this mailbox
    _emails.clear();
    _emails = StorageService.getCachedEmailsForMailbox(email);

    await _addToMailboxHistory(email, domain);
    await _savePreferences();

    // Notify listeners immediately to show cached emails
    notifyListeners();

    // Then fetch fresh emails from API
    fetchEmails();
    _startAutoRefresh();
  }

  // Select or create mailbox with username and domain
  Future<String?> selectMailbox(String username, String domain) async {
    try {
      AppLogger.userAction(
        'Select Mailbox',
        context: {'username': username, 'domain': domain},
      );
      _setLoading(true);

      final email = '$username@$domain';
      _selectedEmail = email;
      _selectedDomain = domain;

      // Clear current emails and load cached emails for this mailbox
      _emails.clear();
      _emails = StorageService.getCachedEmailsForMailbox(email);

      // Add to mailbox history
      await _addToMailboxHistory(email, domain);
      await _savePreferences();

      // Notify listeners immediately to show cached emails
      notifyListeners();

      // Fetch fresh emails for this address (this will create the mailbox if it doesn't exist)
      await fetchEmails();
      _startAutoRefresh();

      _clearError();
      return email;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch emails for selected address
  Future<void> fetchEmails() async {
    if (_selectedEmail == null) return;

    try {
      _setLoading(true);
      final emails = await _apiService.getEmails(_selectedEmail!);

      AppLogger.debug('EmailProvider: Raw emails received', {
        'selectedEmail': _selectedEmail,
        'rawCount': emails.length,
        'emails': emails
            .map(
              (e) => {
                'id': e.id,
                'to': e.to,
                'from': e.from,
                'subject': e.subject,
              },
            )
            .toList(),
      });

      // Only take the configured max emails and filter for this specific mailbox
      final filteredEmails = emails
          .where((email) => email.to == _selectedEmail)
          .take(AppConfig.maxEmailsToShow)
          .toList();

      AppLogger.debug('EmailProvider: Filtered emails', {
        'filteredCount': filteredEmails.length,
        'maxToShow': AppConfig.maxEmailsToShow,
      });

      _emails = filteredEmails;

      // Save emails with mailbox association
      await StorageService.saveEmailsForMailbox(_emails, _selectedEmail!);

      // Reset consecutive failures on success
      _consecutiveFailures = 0;
      _clearError();
    } catch (e) {
      // Increment consecutive failures
      _consecutiveFailures++;

      // Stop auto-refresh if we have 3 consecutive failures
      if (_consecutiveFailures >= 3 && _isAutoRefreshActive) {
        _stopAutoRefresh();
        _setError(
          'Auto-refresh stopped after 3 consecutive failures. Use manual refresh to try again.',
        );
      } else {
        // On error, load cached emails for this mailbox
        _emails = StorageService.getCachedEmailsForMailbox(_selectedEmail!);
        _setError(e.toString());
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get full email content
  Future<EmailModel?> getEmailContent(String emailId) async {
    try {
      // First check cache
      final cachedEmail = StorageService.getEmailById(emailId);
      if (cachedEmail != null) {
        return cachedEmail;
      }

      // Fetch from API
      final email = await _apiService.getEmailContent(emailId);
      await StorageService.saveEmail(email);

      // Update local list if email exists
      final index = _emails.indexWhere((e) => e.id == emailId);
      if (index != -1) {
        _emails[index] = email;
        notifyListeners();
      }

      return email;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Auto-refresh logic
  void _startAutoRefresh() {
    _stopAutoRefresh();
    _refreshStartTime = DateTime.now();
    _currentRefreshInterval = AppConfig.initialRefreshInterval;
    _consecutiveFailures = 0; // Reset failures when starting auto-refresh
    _isAutoRefreshActive = true;
    _scheduleNextRefresh();
  }

  // Public method to start auto-refresh
  void startAutoRefresh() {
    _startAutoRefresh();
  }

  // Public method to stop auto-refresh
  void stopAutoRefresh() {
    _stopAutoRefresh();
  }

  void _scheduleNextRefresh() {
    if (_selectedEmail == null) return;

    _autoRefreshCountdown = _currentRefreshInterval;

    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (
      countdownTimer,
    ) {
      if (_autoRefreshCountdown > 0 && _isAutoRefreshActive) {
        _autoRefreshCountdown--;
        notifyListeners();
      } else {
        countdownTimer.cancel();
      }
    });

    _refreshTimer = Timer(Duration(seconds: _currentRefreshInterval), () {
      if (_isAutoRefreshActive) {
        fetchEmails();
        _updateRefreshInterval();
        _scheduleNextRefresh();
      }
    });
  }

  void _updateRefreshInterval() {
    if (_refreshStartTime == null) return;

    final elapsed = DateTime.now().difference(_refreshStartTime!).inSeconds;

    if (elapsed >= AppConfig.maxRefreshDuration) {
      // Stop refreshing after 5 minutes
      _stopAutoRefresh();
    } else if (elapsed >= AppConfig.mediumPhaseDuration) {
      // After 2 minutes, refresh every 30 seconds
      _currentRefreshInterval = AppConfig.slowRefreshInterval;
    } else if (elapsed >= AppConfig.fastPhaseDuration) {
      // After 30 seconds, refresh every 15 seconds
      _currentRefreshInterval = AppConfig.mediumRefreshInterval;
    }
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isAutoRefreshActive = false;
    _autoRefreshCountdown = 0;
    notifyListeners();
  }

  // Manual refresh
  Future<void> refresh() async {
    await fetchEmails();
    _startAutoRefresh();
  }

  // Clear selected email
  void clearSelectedEmail() {
    _selectedEmail = null;
    _selectedDomain = null;
    _emails.clear();
    _stopAutoRefresh();
    _savePreferences();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Add mailbox to history
  Future<void> _addToMailboxHistory(String email, String domain) async {
    // Check if already exists
    final existingIndex = _mailboxHistory.indexWhere((h) => h.email == email);

    if (existingIndex != -1) {
      // Update existing entry with new last used time
      final existing = _mailboxHistory[existingIndex];
      final updated = existing.copyWith(lastUsed: DateTime.now());
      _mailboxHistory[existingIndex] = updated;
    } else {
      // Create new entry
      final newHistory = MailboxHistory.fromEmailAndDomain(email, domain);
      _mailboxHistory.insert(0, newHistory);
    }

    // Sort by last used (most recent first)
    _mailboxHistory.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

    // Keep only the most recent 50 entries
    if (_mailboxHistory.length > 50) {
      _mailboxHistory = _mailboxHistory.take(50).toList();
    }

    // Save to storage individually
    await StorageService.addMailboxToHistory(email, domain);

    AppLogger.debug('EmailProvider: Added to mailbox history', {
      'email': email,
      'domain': domain,
      'totalHistory': _mailboxHistory.length,
    });
  }

  Future<void> _savePreferences() async {
    final prefs = StorageService.getUserPreferences();
    final updatedPrefs = UserPreferences(
      isDarkMode: prefs.isDarkMode,
      refreshInterval: prefs.refreshInterval,
      selectedEmail: _selectedEmail,
      selectedDomain: _selectedDomain,
      autoRefreshEnabled: prefs.autoRefreshEnabled,
      lastAppOpen: DateTime.now(),
    );
    await StorageService.savePreferences(updatedPrefs);
  }

  // Email expiry logic
  Future<void> cleanupExpiredEmails() async {
    try {
      final currentTime = DateTime.now();
      final emailsToRemove = <String>[];

      // Get ALL cached emails (not just current mailbox)
      final allCachedEmails = StorageService.getCachedEmails();

      // Check each cached email for expiry (1 hour)
      for (final email in allCachedEmails) {
        final emailTime = email.receivedAt;
        final timeDifference = currentTime.difference(emailTime).inHours;

        if (timeDifference >= 1) {
          // 1 hour expiry
          emailsToRemove.add(email.id);
        }
      }

      // Remove expired emails from storage
      if (emailsToRemove.isNotEmpty) {
        for (final emailId in emailsToRemove) {
          await StorageService.removeEmail(emailId);
        }

        // Also remove from current emails list if they belong to selected mailbox
        final currentEmailsToRemove = _emails
            .where((email) => emailsToRemove.contains(email.id))
            .map((email) => email.id)
            .toList();

        if (currentEmailsToRemove.isNotEmpty) {
          _emails.removeWhere((email) => emailsToRemove.contains(email.id));
          notifyListeners();
        }

        AppLogger.info('EmailProvider: Cleaned up expired emails', {
          'removed_count': emailsToRemove.length,
          'current_mailbox_affected': currentEmailsToRemove.length,
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'EmailProvider: Failed to cleanup expired emails',
        e,
        stackTrace,
      );
    }
  }

  // Start periodic cleanup timer
  Timer? _cleanupTimer;

  void _startPeriodicCleanup() {
    _stopPeriodicCleanup();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      cleanupExpiredEmails();
    });
  }

  void _stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  // Get cached emails for a specific mailbox (used by history)
  List<EmailModel> getEmailsForMailbox(String mailbox) {
    return StorageService.getCachedEmailsForMailbox(mailbox);
  }

  // Delete a mailbox from history and all its associated emails
  Future<void> deleteMailboxFromHistory(String email) async {
    try {
      _setLoading(true);

      // Delete from storage
      await StorageService.deleteMailboxHistory(email);

      // Refresh the mailbox history list
      _mailboxHistory = StorageService.getCachedMailboxHistories();

      // If this was the currently selected email, clear it
      if (_selectedEmail == email) {
        clearSelectedEmail();
      }

      _clearError();
    } catch (e) {
      _setError('Failed to delete mailbox: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Validate that the selected domain exists in available domains
  void _validateSelectedDomain() {
    if (_selectedDomain != null && _domains.isNotEmpty) {
      final domainExists = _domains.any(
        (domain) => domain.domain == _selectedDomain,
      );
      if (!domainExists) {
        AppLogger.debug(
          'EmailProvider: Selected domain not found, resetting to first available',
          {
            'oldDomain': _selectedDomain,
            'availableDomains': _domains.map((d) => d.domain).toList(),
          },
        );
        // Reset to first available domain
        _selectedDomain = _domains.first.domain;
        // Update preferences to persist the change
        _savePreferences();
      }
    } else if (_selectedDomain == null && _domains.isNotEmpty) {
      // No domain selected, set to first available
      _selectedDomain = _domains.first.domain;
      _savePreferences();
    }
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    _stopPeriodicCleanup();
    super.dispose();
  }
}
