import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/email_model.dart';
import '../models/domain_model.dart';
import '../models/user_preferences.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class EmailProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  List<EmailModel> _emails = [];
  List<DomainModel> _domains = [];
  String? _selectedEmail;
  String? _selectedDomain;
  bool _isLoading = false;
  String? _error;

  // Auto-refresh logic
  Timer? _refreshTimer;
  DateTime? _refreshStartTime;
  int _currentRefreshInterval = AppConfig.initialRefreshInterval;

  // Getters
  List<EmailModel> get emails => _emails;
  List<DomainModel> get domains => _domains;
  String? get selectedEmail => _selectedEmail;
  String? get selectedDomain => _selectedDomain;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSelectedEmail => _selectedEmail != null;

  EmailProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    // Load cached data
    _emails = StorageService.getCachedEmails();
    _domains = StorageService.getCachedDomains();

    final prefs = StorageService.getUserPreferences();
    _selectedEmail = prefs.selectedEmail;
    _selectedDomain = prefs.selectedDomain;

    notifyListeners();

    // Fetch fresh data
    await fetchDomains();
    if (_selectedEmail != null) {
      await fetchEmails();
      _startAutoRefresh();
    }
  }

  // Fetch available domains
  Future<void> fetchDomains() async {
    try {
      _setLoading(true);
      final domains = await _apiService.getDomains();
      _domains = domains;
      await StorageService.saveDomains(domains);
      _clearError();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Generate new email address
  Future<String?> generateEmail(String domain) async {
    try {
      _setLoading(true);
      final email = await _apiService.generateEmail(domain);
      _selectedEmail = email;
      _selectedDomain = domain;
      await _savePreferences();
      _clearError();
      return email;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Select existing email
  void selectEmail(String email, String domain) {
    _selectedEmail = email;
    _selectedDomain = domain;
    _savePreferences();
    fetchEmails();
    _startAutoRefresh();
    notifyListeners();
  }

  // Fetch emails for selected address
  Future<void> fetchEmails() async {
    if (_selectedEmail == null) return;

    try {
      _setLoading(true);
      final emails = await _apiService.getEmails(_selectedEmail!);
      _emails = emails.take(AppConfig.maxEmailsToShow).toList();
      await StorageService.saveEmails(_emails);
      _clearError();
    } catch (e) {
      _setError(e.toString());
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
    _scheduleNextRefresh();
  }

  void _scheduleNextRefresh() {
    if (_selectedEmail == null) return;

    _refreshTimer = Timer(Duration(seconds: _currentRefreshInterval), () {
      fetchEmails();
      _updateRefreshInterval();
      _scheduleNextRefresh();
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

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }
}
