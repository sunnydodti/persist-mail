import 'package:hive/hive.dart';

part 'user_preferences.g.dart';

@HiveType(typeId: 2)
class UserPreferences extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  int refreshInterval;

  @HiveField(2)
  String? selectedEmail;

  @HiveField(3)
  String? selectedDomain;

  @HiveField(4)
  bool autoRefreshEnabled;

  @HiveField(5)
  DateTime? lastAppOpen;

  UserPreferences({
    this.isDarkMode = false,
    this.refreshInterval = 5,
    this.selectedEmail,
    this.selectedDomain,
    this.autoRefreshEnabled = true,
    this.lastAppOpen,
  });

  factory UserPreferences.defaultPreferences() {
    return UserPreferences(
      isDarkMode: false,
      refreshInterval: 5,
      autoRefreshEnabled: true,
      lastAppOpen: DateTime.now(),
    );
  }
}
