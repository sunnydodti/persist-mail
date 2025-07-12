// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persist_mail_ui/app.dart';
import 'package:persist_mail_ui/services/storage_service.dart';
import 'package:persist_mail_ui/config/app_config.dart';
import 'package:persist_mail_ui/base/enums.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Initialize test environment
    await Hive.initFlutter();
    await StorageService.init();
    AppConfig.currentFlavor = Flavor.DEV;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const PersistMailApp());

    // Verify that the app loads
    expect(find.text('PersistMail'), findsOneWidget);
  });
}
