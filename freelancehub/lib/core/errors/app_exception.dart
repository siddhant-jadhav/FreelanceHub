/// Clean application error abstraction for FreelanceHub.
/// Maps Firebase exceptions, network timeouts, and permission errors
/// to user-friendly messages without exposing raw database exceptions to UI.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Factory to map Firebase & general exceptions to friendly [AppException]s
  factory AppException.fromAuth(String code, [String? fallbackMessage]) {
    switch (code) {
      case 'user-not-found':
        return const AppException(
          message: 'No user found with this email or username.',
          code: 'user-not-found',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AppException(
          message: 'Incorrect password. Please verify your credentials.',
          code: 'wrong-password',
        );
      case 'email-already-in-use':
        return const AppException(
          message: 'An account with this email is already registered. Try logging in.',
          code: 'email-already-in-use',
        );
      case 'weak-password':
        return const AppException(
          message: 'Password is too weak. Please use at least 6 characters.',
          code: 'weak-password',
        );
      case 'invalid-email':
        return const AppException(
          message: 'Please provide a valid email address.',
          code: 'invalid-email',
        );
      case 'network-request-failed':
        return const AppException(
          message: 'Network connection failed. Please check your internet connection.',
          code: 'network-unavailable',
        );
      default:
        return AppException(
          message: fallbackMessage ?? 'Authentication failed ($code).',
          code: code,
        );
    }
  }

  /// Factory for Firestore-specific error codes
  factory AppException.fromFirestore(String code, [String? fallbackMessage]) {
    switch (code) {
      case 'permission-denied':
        return const AppException(
          message: 'Access denied: You do not have permission to perform this action.',
          code: 'permission-denied',
        );
      case 'not-found':
        return const AppException(
          message: 'The requested resource was not found.',
          code: 'not-found',
        );
      case 'already-exists':
        return const AppException(
          message: 'This document already exists.',
          code: 'already-exists',
        );
      case 'resource-exhausted':
        return const AppException(
          message: 'Quota exceeded. Please try again later.',
          code: 'resource-exhausted',
        );
      default:
        return AppException(
          message: fallbackMessage ?? 'Firestore error ($code).',
          code: code,
        );
    }
  }

  factory AppException.from(dynamic error) {
    if (error is AppException) return error;

    final errorString = error.toString().toLowerCase();

    // Common Firebase Auth error codes
    if (errorString.contains('user-not-found')) {
      return const AppException(
        message: 'No account found with this email or username.',
        code: 'user-not-found',
      );
    }
    if (errorString.contains('wrong-password') ||
        errorString.contains('invalid-credential')) {
      return const AppException(
        message: 'Incorrect email or password. Please verify your credentials.',
        code: 'wrong-password',
      );
    }
    if (errorString.contains('email-already-in-use')) {
      return const AppException(
        message: 'An account with this email already exists. Try logging in.',
        code: 'email-already-in-use',
      );
    }
    if (errorString.contains('weak-password')) {
      return const AppException(
        message: 'Password is too weak. Please use at least 6 characters.',
        code: 'weak-password',
      );
    }
    if (errorString.contains('invalid-email')) {
      return const AppException(
        message: 'Please provide a valid email address.',
        code: 'invalid-email',
      );
    }
    if (errorString.contains('permission-denied')) {
      return const AppException(
        message: 'Access denied: You do not have permission to perform this action.',
        code: 'permission-denied',
      );
    }
    if (errorString.contains('network-request-failed') ||
        errorString.contains('unavailable')) {
      return const AppException(
        message: 'Network connection issue. Please check your internet connection.',
        code: 'network-unavailable',
      );
    }
    if (errorString.contains('not-found')) {
      return const AppException(
        message: 'Requested document or resource was not found.',
        code: 'not-found',
      );
    }

    return AppException(
      message: error is Exception
          ? error.toString().replaceAll('Exception: ', '')
          : 'An unexpected error occurred. Please try again.',
      originalError: error,
    );
  }
}
