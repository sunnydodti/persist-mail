import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persist_mail_ui/app.dart';
import 'package:persist_mail_ui/base/enums.dart';
import 'package:persist_mail_ui/config/app_config.dart';
import 'package:persist_mail_ui/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize storage
  await StorageService.init();

  // Set flavor for alpha
  AppConfig.currentFlavor = Flavor.ALPHA;

  runApp(const PersistMailApp());
}
