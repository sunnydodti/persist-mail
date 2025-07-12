import '../base/enums.dart';

class AppConfig {
  static const String appName = 'PersistMail';

  // API Configuration based on flavor
  static String get baseUrl {
    switch (currentFlavor) {
      case Flavor.DEV:
        return 'http://192.168.137.160:8000';
      case Flavor.STG:
        return 'https://staging-api.persistmail.com';
      case Flavor.PRD:
        return 'https://api.persistmail.com';
      case Flavor.ALPHA:
        return 'http://192.168.137.160:8001';
      case Flavor.BETA:
        return 'https://beta-api.persistmail.com';
    }
  }

  // Auto-refresh intervals in seconds
  static const int initialRefreshInterval = 5;
  static const int mediumRefreshInterval = 15;
  static const int slowRefreshInterval = 30;
  static const int maxRefreshDuration = 300; // 5 minutes
  static const int fastPhaseDuration = 30; // 30 seconds
  static const int mediumPhaseDuration = 120; // 2 minutes

  // UI Configuration
  static const int maxEmailsToShow = 15;
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Storage Keys
  static const String emailBoxName = 'emails';
  static const String preferencesBoxName = 'preferences';
  static const String domainsBoxName = 'domains';

  // Current flavor (to be set at app startup)
  static Flavor currentFlavor = Flavor.DEV;
}
