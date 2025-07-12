import 'package:flutter/material.dart';

class SnackbarService {
  // Global keys for context-free navigation and snackbars
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Get the current context
  static BuildContext? get currentContext => navigatorKey.currentState?.context;

  // Show success snackbar
  static void showSuccess(String message, {Duration? duration}) {
    _showSnackbar(
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  // Show error snackbar
  static void showError(String message, {Duration? duration}) {
    _showSnackbar(
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration,
    );
  }

  // Show warning snackbar
  static void showWarning(String message, {Duration? duration}) {
    _showSnackbar(
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration,
    );
  }

  // Show info snackbar
  static void showInfo(String message, {Duration? duration}) {
    _showSnackbar(
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: duration,
    );
  }

  // Show custom snackbar
  static void showCustom({
    required String message,
    Color? backgroundColor,
    IconData? icon,
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackbar(
      message: message,
      backgroundColor: backgroundColor ?? Colors.grey[800]!,
      icon: icon,
      duration: duration,
      action: action,
    );
  }

  // Private method to show snackbar
  static void _showSnackbar({
    required String message,
    required Color backgroundColor,
    IconData? icon,
    Duration? duration,
    SnackBarAction? action,
  }) {
    try {
      final snackBar = SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        action: action,
      );

      scaffoldMessengerKey.currentState?.showSnackBar(snackBar);
    } catch (e) {
      // Fallback: print to debug console if snackbar fails
      debugPrint('Snackbar Error: $message');
    }
  }

  // Hide current snackbar
  static void hideCurrentSnackbar() {
    try {
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    } catch (e) {
      debugPrint('Error hiding snackbar: $e');
    }
  }

  // Clear all snackbars
  static void clearSnackbars() {
    try {
      scaffoldMessengerKey.currentState?.clearSnackBars();
    } catch (e) {
      debugPrint('Error clearing snackbars: $e');
    }
  }
}
