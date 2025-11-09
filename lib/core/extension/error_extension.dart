import 'package:flutter/material.dart';

/// Extension that provides user-friendly error handling and display
extension ErrorExtension on dynamic {
  /// Get user-friendly error message based on error type
  String get userFriendlyMessage {
    // Handle String errors
    if (this is String) {
      return _handleStringError(this as String);
    }

    // Handle HTTP status codes
    if (this is int) {
      return _handleStatusCode(this as int);
    }

    // Handle HTTP errors
    if (toString().contains('HttpException') ||
        toString().contains('SocketException') ||
        toString().contains('ClientException')) {
      return _handleNetworkError();
    }

    // Handle timeout errors
    if (toString().contains('TimeoutException') ||
        toString().contains('timeout')) {
      return _handleTimeoutError();
    }

    // Handle format errors
    if (toString().contains('FormatException') || toString().contains('JSON')) {
      return _handleFormatError();
    }

    // Handle permission errors
    if (toString().contains('Permission') ||
        toString().contains('permission')) {
      return _handlePermissionError();
    }

    // Default fallback message
    return _handleGenericError();
  }

  /// Show user-friendly error snackbar that auto-dismisses
  void showError(BuildContext context, {Duration? duration}) {
    if (!context.mounted) return;

    final message = userFriendlyMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// Show success message
  void showSuccess(
    BuildContext context, {
    String? customMessage,
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final message = customMessage ?? 'Operation completed successfully';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show warning message
  void showWarning(
    BuildContext context, {
    String? customMessage,
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final message = customMessage ?? 'Please check your input';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show info message
  void showInfo(
    BuildContext context, {
    String? customMessage,
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final message = customMessage ?? 'Information';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Helper method to handle string errors
  String _handleStringError(String error) {
    final lowerError = error.toLowerCase();

    // Common authentication errors
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

    // Network related
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Check your internet connection';
    }
    if (lowerError.contains('timeout')) {
      return 'Request timed out. Please try again';
    }
    if (lowerError.contains('server')) {
      return 'Server is temporarily unavailable';
    }

    // File/Image errors
    if (lowerError.contains('image') || lowerError.contains('photo')) {
      return 'Unable to process image. Try a different photo';
    }
    if (lowerError.contains('file') || lowerError.contains('upload')) {
      return 'File upload failed. Please try again';
    }

    // Permission errors
    if (lowerError.contains('permission') || lowerError.contains('denied')) {
      return 'Permission denied. Please check app settings';
    }

    // Generic user-friendly messages
    if (lowerError.contains('unauthorized')) {
      return 'Please sign in again';
    }
    if (lowerError.contains('forbidden')) {
      return 'You don\'t have permission to do this';
    }
    if (lowerError.contains('not found')) {
      return 'The requested item was not found';
    }
    if (lowerError.contains('conflict')) {
      return 'This action conflicts with existing data';
    }
    if (lowerError.contains('rate limit')) {
      return 'Too many requests. Please wait a moment';
    }

    // Return cleaned up version of the error if no match
    final cleaned =
        error
            .replaceAllMapped(
              RegExp(r'[a-zA-Z]*Exception:\s*', caseSensitive: false),
              (match) => '',
            )
            .trim();

    return cleaned.isEmpty ? 'Something went wrong. Please try again' : cleaned;
  }

  /// Helper method to handle HTTP status codes
  String _handleStatusCode(int statusCode) {
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

  /// Helper method to handle network errors
  String _handleNetworkError() {
    return 'No internet connection. Please check your network settings';
  }

  /// Helper method to handle timeout errors
  String _handleTimeoutError() {
    return 'Request timed out. Please try again';
  }

  /// Helper method to handle format errors
  String _handleFormatError() {
    return 'Invalid data format. Please try again';
  }

  /// Helper method to handle permission errors
  String _handlePermissionError() {
    return 'Permission required. Please check app settings';
  }

  /// Helper method to handle generic errors
  String _handleGenericError() {
    final errorStr = toString();

    // Remove technical details for user-friendly display
    return errorStr.length > 100
        ? 'Something went wrong. Please try again'
        : errorStr;
  }
}

/// Utility class for showing different types of messages
class MessageHelper {
  /// Show success message with auto-dismiss
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show error message with auto-dismiss
  static void showError(
    BuildContext context,
    dynamic error, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final message = error is String ? error : error.userFriendlyMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// Show warning message with auto-dismiss
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show info message with auto-dismiss
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: duration ?? const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
