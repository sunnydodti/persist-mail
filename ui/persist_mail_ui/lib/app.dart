import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:persist_mail_ui/providers/theme_provider.dart';
import 'package:persist_mail_ui/providers/email_provider.dart';
import 'package:persist_mail_ui/providers/settings_provider.dart';
import 'package:persist_mail_ui/services/global_error_handler.dart';
import 'package:persist_mail_ui/services/snackbar_service.dart';
import 'package:persist_mail_ui/services/logging_service.dart';
import 'package:persist_mail_ui/config/app_config.dart';
import 'package:persist_mail_ui/routes/app_routes.dart';
import 'package:persist_mail_ui/screens/home_screen.dart';

class PersistMailApp extends StatelessWidget {
  const PersistMailApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('PersistMailApp: Building widget tree');
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          AppLogger.debug('Creating ThemeProvider');
          return ThemeProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          AppLogger.debug('Creating SettingsProvider');
          return SettingsProvider();
        }),
        ChangeNotifierProvider(create: (_) {
          AppLogger.debug('Creating EmailProvider');
          return EmailProvider();
        }),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          AppLogger.debug('Building MaterialApp with theme', {
            'isDarkMode': themeProvider.isDarkMode,
            'themeMode': themeProvider.themeMode.toString(),
          });
          
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,

            // Global Navigator Key for context-free navigation
            navigatorKey: SnackbarService.navigatorKey,

            // Global Error Handling
            builder: (context, widget) {
              ErrorWidget.builder = GlobalErrorHandler.customErrorWidget;
              return GlobalErrorHandler(
                child: widget ?? const SizedBox.shrink(),
              );
            },

            // Theme Configuration
            theme: themeProvider.currentTheme,
            darkTheme: themeProvider.currentTheme,
            themeMode: themeProvider.themeMode,

            // Routing
            onGenerateRoute: AppRoutes.generateRoute,
            initialRoute: AppRoutes.home,

            // Home Screen (fallback)
            home: const HomeScreen(),

            // Global Scaffold Messenger Key
            scaffoldMessengerKey: SnackbarService.scaffoldMessengerKey,
          );
        },
      ),
    );
  }
}
