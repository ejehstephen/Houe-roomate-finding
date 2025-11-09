import 'package:flutter/material.dart';

/// Utility class for showing different types of messages with consistent styling
/// and auto-dismiss behavior throughout the app
class MessageUtil {
  /// Show success message with green styling
  ///
  /// [context] - BuildContext for showing the snackbar
  /// [message] - Success message to display
  /// [duration] - How long to show the message (defaults to 2 seconds)
  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Show error message with red styling
  ///
  /// [context] - BuildContext for showing the snackbar
  /// [error] - Error object, string, or status code to display user-friendly message for
  /// [duration] - How long to show the message (defaults to 3 seconds for errors)
  static void error(BuildContext context, dynamic error, {Duration? duration}) {
    if (!context.mounted) return;

    final message = _getUserFriendlyMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show warning message with orange styling
  ///
  /// [context] - BuildContext for showing the snackbar
  /// [message] - Warning message to display
  /// [duration] - How long to show the message (defaults to 3 seconds)
  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Show info message with blue styling
  ///
  /// [context] - BuildContext for showing the snackbar
  /// [message] - Info message to display
  /// [duration] - How long to show the message (defaults to 2 seconds)
  static void info(BuildContext context, String message, {Duration? duration}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Show loading message with spinner
  ///
  /// [context] - BuildContext for showing the snackbar
  /// [message] - Loading message to display
  ///
  /// Returns a SnackBar controller so you can hide it later
  static SnackBarController loading(BuildContext context, String message) {
    if (!context.mounted) {
      return SnackBarController();
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.grey.shade800,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: const Duration(minutes: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    return SnackBarController();
  }

  /// Helper method to convert various error types to user-friendly messages
  static String _getUserFriendlyMessage(dynamic error) {
    // Handle String errors
    if (error is String) {
      return _handleStringError(error);
    }

    // Handle HTTP status codes
    if (error is int) {
      return _handleStatusCode(error);
    }

    // Handle common error patterns
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again';
    }
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'No internet connection. Please check your network';
    }
    if (errorStr.contains('unauthorized')) {
      return 'Please sign in again';
    }
    if (errorStr.contains('forbidden')) {
      return 'You don\'t have permission to do this';
    }
    if (errorStr.contains('not found')) {
      return 'The requested item was not found';
    }
    if (errorStr.contains('server')) {
      return 'Server error. Please try again later';
    }

    // Clean up technical error messages
    final cleaned =
        error
            .toString()
            .replaceAllMapped(
              RegExp(r'[a-zA-Z]*Exception:\s*', caseSensitive: false),
              (match) => '',
            )
            .trim();

    return cleaned.isEmpty ? 'Something went wrong. Please try again' : cleaned;
  }

  /// Handle string-based errors
  static String _handleStringError(String error) {
    final lowerError = error.toLowerCase();

    // Authentication errors
    if (lowerError.contains('email') && lowerError.contains('invalid')) {
      return 'Please enter a valid email address';
    }
    if (lowerError.contains('password') && lowerError.contains('incorrect')) {
      return 'Incorrect password. Please try again';
    }
    if (lowerError.contains('user') && lowerError.contains('not found')) {
      return 'Account not found. Please check your email';
    }
    if (lowerError.contains('email') && lowerError.contains('already exists')) {
      return 'An account with this email already exists';
    }

    // Validation errors
    if (lowerError.contains('required') || lowerError.contains('empty')) {
      return 'Please fill in all required fields';
    }
    if (lowerError.contains('format') && lowerError.contains('email')) {
      return 'Please enter a valid email address';
    }

    // Return cleaned version
    return error.trim();
  }

  /// Handle HTTP status codes
  static String _handleStatusCode(int statusCode) {
    switch (statusCode) {
      // 2xx Success
      case 200:
      case 201:
        return 'Success';
      case 204:
        return 'Operation completed';

      // 4xx Client Errors
      case 400:
        return 'Invalid request. Please check your input';
      case 401:
        return 'Please sign in to continue';
      case 403:
        return 'You don\'t have permission to do this';
      case 404:
        return 'The requested item was not found';
      case 409:
        return 'This already exists';
      case 422:
        return 'Please check your input';
      case 429:
        return 'Too many requests. Please wait';

      // 5xx Server Errors
      case 500:
        return 'Server error. Please try again later';
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable';

      default:
        return 'Something went wrong. Please try again';
    }
  }

  /// Hide any currently showing snackbar
  static void hideCurrent(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  /// Hide all snackbars
  static void hideAll(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }
}

/// Controller for managing snackbar lifecycle
class SnackBarController {
  /// Hide the snackbar this controller manages
  void hide(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }
}
