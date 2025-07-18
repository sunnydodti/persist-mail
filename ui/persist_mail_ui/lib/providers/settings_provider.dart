import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:persist_mail_ui/services/logging_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _autoRefreshKey = 'auto_refresh';
  static const String _refreshIntervalKey = 'refresh_interval';
  static const String _cacheEnabledKey = 'cache_enabled';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _maxEmailsKey = 'max_emails';

  late Box _settingsBox;
  bool _isInitialized = false;

  // Default values
  bool _autoRefresh = true;
  int _refreshInterval = 5; // seconds
  bool _cacheEnabled = true;
  bool _notificationsEnabled = true;
  int _maxEmails = 15;

  // Getters
  bool get autoRefresh => _autoRefresh;
  int get refreshInterval => _refreshInterval;
  bool get cacheEnabled => _cacheEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  int get maxEmails => _maxEmails;
  bool get isInitialized => _isInitialized;

  // Initialize the provider
  Future<void> init() async {
    try {
      AppLogger.debug('SettingsProvider: Initializing');
      _settingsBox = await Hive.openBox(_boxName);
      await _loadSettings();
      _isInitialized = true;
      AppLogger.info('SettingsProvider: Initialized successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('SettingsProvider: Failed to initialize', e, stackTrace);
    }
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    try {
      _autoRefresh = _settingsBox.get(_autoRefreshKey, defaultValue: true);
      _refreshInterval = _settingsBox.get(_refreshIntervalKey, defaultValue: 5);
      _cacheEnabled = _settingsBox.get(_cacheEnabledKey, defaultValue: true);
      _notificationsEnabled = _settingsBox.get(
        _notificationsEnabledKey,
        defaultValue: true,
      );
      _maxEmails = _settingsBox.get(_maxEmailsKey, defaultValue: 15);

      AppLogger.debug('SettingsProvider: Settings loaded', {
        'autoRefresh': _autoRefresh,
        'refreshInterval': _refreshInterval,
        'cacheEnabled': _cacheEnabled,
        'notificationsEnabled': _notificationsEnabled,
        'maxEmails': _maxEmails,
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'SettingsProvider: Failed to load settings',
        e,
        stackTrace,
      );
    }
  }

  // Save setting to storage
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox.put(key, value);
      AppLogger.storageWrite(key, type: 'settings');
    } catch (e) {
      AppLogger.storageError('save', key, e);
    }
  }

  // Set auto refresh
  Future<void> setAutoRefresh(bool value) async {
    _autoRefresh = value;
    await _saveSetting(_autoRefreshKey, value);
    AppLogger.settingChanged('autoRefresh', value);
    notifyListeners();
  }

  // Set refresh interval
  Future<void> setRefreshInterval(int seconds) async {
    if (seconds >= 1 && seconds <= 300) {
      // 1 second to 5 minutes
      _refreshInterval = seconds;
      await _saveSetting(_refreshIntervalKey, seconds);
      AppLogger.settingChanged('refreshInterval', seconds);
      notifyListeners();
    }
  }

  // Set cache enabled
  Future<void> setCacheEnabled(bool value) async {
    _cacheEnabled = value;
    await _saveSetting(_cacheEnabledKey, value);
    AppLogger.settingChanged('cacheEnabled', value);
    notifyListeners();
  }

  // Set notifications enabled
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _saveSetting(_notificationsEnabledKey, value);
    AppLogger.settingChanged('notificationsEnabled', value);
    notifyListeners();
  }

  // Set max emails
  Future<void> setMaxEmails(int count) async {
    if (count >= 5 && count <= 50) {
      // Between 5 and 50 emails
      _maxEmails = count;
      await _saveSetting(_maxEmailsKey, count);
      AppLogger.settingChanged('maxEmails', count);
      notifyListeners();
    }
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    try {
      AppLogger.warning('SettingsProvider: Resetting all settings to defaults');
      await _settingsBox.clear();
      await _loadSettings();
      AppLogger.info('SettingsProvider: Settings reset completed');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(
        'SettingsProvider: Failed to reset settings',
        e,
        stackTrace,
      );
    }
  }

  // Get all settings as a map
  Map<String, dynamic> getAllSettings() {
    return {
      'autoRefresh': _autoRefresh,
      'refreshInterval': _refreshInterval,
      'cacheEnabled': _cacheEnabled,
      'notificationsEnabled': _notificationsEnabled,
      'maxEmails': _maxEmails,
    };
  }

  @override
  void dispose() {
    _settingsBox.close();
    super.dispose();
  }
}
