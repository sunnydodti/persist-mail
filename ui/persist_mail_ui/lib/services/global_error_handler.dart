import 'package:flutter/material.dart';
import 'package:persist_mail_ui/services/snackbar_service.dart';

class GlobalErrorHandler extends StatefulWidget {
  final Widget child;

  const GlobalErrorHandler({super.key, required this.child});

  @override
  State<GlobalErrorHandler> createState() => _GlobalErrorHandlerState();

  // Custom error widget builder
  static Widget customErrorWidget(FlutterErrorDetails errorDetails) {
    // Log error for debugging
    debugPrint('Flutter Error: ${errorDetails.exception}');
    debugPrint('Stack trace: ${errorDetails.stack}');

    // Show user-friendly error message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SnackbarService.showError('Something went wrong. Please try again.');
    });

    // Return a simple error widget
    return Material(
      child: Container(
        color: Colors.red.shade50,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please restart the app',
                style: TextStyle(fontSize: 14, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalErrorHandlerState extends State<GlobalErrorHandler> {
  @override
  void initState() {
    super.initState();

    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');

      // Show user-friendly error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarService.showError('An error occurred. Please try again.');
      });

      // Call the original error handler for debugging
      FlutterError.presentError(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
