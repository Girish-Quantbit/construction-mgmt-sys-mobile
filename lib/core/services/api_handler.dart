import '../error/failures.dart';
import '../error/session_manager.dart';

/// Helper to wrap API calls, catch exceptions, check for session expiration,
/// and throw domain-specific exceptions.
class ApiHandler {
  static Future<T> call<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } catch (e) {
      final message = e.toString();
      if (message.contains('PermissionError') ||
          message.contains('You are not permitted to access this resource') ||
          message.contains('Login to access')) {
        SessionManager.triggerLogout('You have been logged out, please login');
        throw SessionExpiredException(message);
      }
      throw ServerException(message);
    }
  }
}
