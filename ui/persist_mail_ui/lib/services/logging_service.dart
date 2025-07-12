import 'package:logger/logger.dart';
import 'package:persist_mail_ui/config/app_config.dart';
import 'package:persist_mail_ui/base/enums.dart';

class AppLogger {
  static Logger? _logger;

  // Get the singleton logger instance
  static Logger get instance {
    _logger ??= _createLogger();
    return _logger!;
  }

  // Create logger with appropriate configuration based on flavor
  static Logger _createLogger() {
    return Logger(
      filter: _getLogFilter(),
      printer: _getLogPrinter(),
      output: _getLogOutput(),
    );
  }

  // Log filter based on flavor
  static LogFilter _getLogFilter() {
    switch (AppConfig.currentFlavor) {
      case Flavor.DEV:
      case Flavor.ALPHA:
        return DevelopmentFilter(); // Show all logs in development
      case Flavor.STG:
      case Flavor.BETA:
        return ProductionFilter(); // Show info and above in staging/beta
      case Flavor.PRD:
        return ProductionFilter(); // Show warnings and above in production
    }
  }

  // Log printer based on flavor
  static LogPrinter _getLogPrinter() {
    switch (AppConfig.currentFlavor) {
      case Flavor.DEV:
      case Flavor.ALPHA:
        return PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          printTime: true,
        );
      case Flavor.STG:
      case Flavor.BETA:
      case Flavor.PRD:
        return SimplePrinter(colors: false, printTime: true);
    }
  }

  // Log output
  static LogOutput _getLogOutput() {
    return ConsoleOutput();
  }

  // Convenience methods
  static void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.t(message, error: error, stackTrace: stackTrace);
  }

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.e(message, error: error, stackTrace: stackTrace);
  }

  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    instance.f(message, error: error, stackTrace: stackTrace);
  }

  // Feature-specific logging methods
  static void apiRequest(
    String method,
    String url, {
    Map<String, dynamic>? data,
  }) {
    final safeData = _safeLogData(data);
    debug(
      'API Request: $method $url${safeData != null ? ' - Data: $safeData' : ''}',
    );
  }

  static void apiResponse(
    String method,
    String url,
    int statusCode, {
    dynamic data,
  }) {
    try {
      final safeData = _safeLogData(data);
      final message =
          'API Response: $method $url [$statusCode]${safeData != null ? ' - Data: $safeData' : ''}';

      if (statusCode >= 200 && statusCode < 300) {
        debug(message);
      } else {
        warning(message);
      }
    } catch (e) {
      debug(
        'API Response: $method $url [$statusCode] (data logging failed: $e)',
      );
    }
  }

  static dynamic _safeLogData(dynamic data) {
    try {
      if (data == null) return null;
      if (data is String || data is num || data is bool) return data;
      if (data is List || data is Map) {
        return data.toString().length > 1000
            ? '${data.toString().substring(0, 1000)}...(truncated)'
            : data;
      }
      return data.toString();
    } catch (e) {
      return 'Failed to serialize data: $e';
    }
  }

  static void navigation(
    String from,
    String to, {
    Map<String, dynamic>? arguments,
  }) {
    final argsStr = arguments != null
        ? ' - Args: ${_safeLogData(arguments)}'
        : '';
    debug('Navigation: $from -> $to$argsStr');
  }

  static void userAction(String action, {Map<String, dynamic>? context}) {
    final contextStr = context != null
        ? ' - Context: ${_safeLogData(context)}'
        : '';
    info('User Action: $action$contextStr');
  }

  static void cacheHit(String key, {String? type}) {
    verbose('Cache Hit: $key${type != null ? ' ($type)' : ''}');
  }

  static void cacheMiss(String key, {String? type}) {
    debug('Cache Miss: $key${type != null ? ' ($type)' : ''}');
  }

  static void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    final contextStr = context != null
        ? ' - Context: ${_safeLogData(context)}'
        : '';
    final message =
        'Performance: $operation took ${duration.inMilliseconds}ms$contextStr';

    if (duration.inMilliseconds > 1000) {
      warning(
        'Slow Operation: $operation took ${duration.inMilliseconds}ms$contextStr',
      );
    } else {
      debug(message);
    }
  }

  // Email-specific logging
  static void emailReceived(String emailId, String subject) {
    info('Email Received: $emailId - $subject');
  }

  static void emailOpened(String emailId) {
    userAction('Email Opened', context: {'emailId': emailId});
  }

  static void emailCopied(String email) {
    userAction('Email Copied', context: {'email': email});
  }

  static void refreshStarted(String reason) {
    debug('Refresh Started: $reason');
  }

  static void refreshCompleted(
    String reason,
    int emailCount,
    Duration duration,
  ) {
    info(
      'Refresh Completed: $reason - $emailCount emails in ${duration.inMilliseconds}ms',
    );
  }

  // Theme and settings logging
  static void themeChanged(bool isDarkMode) {
    userAction('Theme Changed', context: {'isDarkMode': isDarkMode});
  }

  static void settingChanged(String setting, dynamic value) {
    userAction(
      'Setting Changed',
      context: {'setting': setting, 'value': value},
    );
  }

  // Storage logging
  static void storageWrite(String key, {String? type}) {
    debug('Storage Write: $key${type != null ? ' ($type)' : ''}');
  }

  static void storageRead(String key, {String? type, bool found = true}) {
    if (found) {
      verbose('Storage Read: $key${type != null ? ' ($type)' : ''}');
    } else {
      debug('Storage Miss: $key${type != null ? ' ($type)' : ''}');
    }
  }

  static void storageError(String operation, String key, dynamic error) {
    AppLogger.error('Storage Error: $operation for $key', error);
  }
}
