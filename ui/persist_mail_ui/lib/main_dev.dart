import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persist_mail_ui/app.dart';
import 'package:persist_mail_ui/base/enums.dart';
import 'package:persist_mail_ui/config/app_config.dart';
import 'package:persist_mail_ui/services/storage_service.dart';
import 'package:persist_mail_ui/services/logging_service.dart';
import 'package:persist_mail_ui/models/domain_model.dart';
import 'package:persist_mail_ui/models/email_model.dart';
import 'package:persist_mail_ui/models/user_preferences.dart';
import 'package:persist_mail_ui/models/mailbox_history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('App Starting - Development Flavor');

  // Initialize Hive
  AppLogger.debug('Initializing Hive');
  await Hive.initFlutter();

  // Register Hive adapters
  AppLogger.debug('Registering Hive Adapters');
  Hive.registerAdapter(DomainModelAdapter());
  Hive.registerAdapter(EmailModelAdapter());
  Hive.registerAdapter(UserPreferencesAdapter());
  Hive.registerAdapter(MailboxHistoryAdapter());

  // Initialize storage
  AppLogger.debug('Initializing Storage Service');
  await StorageService.init();

  // Set flavor for development
  AppConfig.currentFlavor = Flavor.DEV;
  AppLogger.info('App Configuration Set', {'flavor': 'DEV'});

  AppLogger.info('Launching PersistMail App (Development)');
  runApp(const PersistMailApp());
}
