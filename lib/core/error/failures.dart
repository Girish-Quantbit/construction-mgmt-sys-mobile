import 'dart:convert';

abstract class Failure {
  final String message;
  Failure(String rawMessage) : message = _cleanErrorMessage(rawMessage);
}

class AuthFailure extends Failure {
  AuthFailure(super.message);
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}

class SessionExpiredFailure extends Failure {
  SessionExpiredFailure(super.message);
}

class CacheFailure extends Failure {
  CacheFailure(super.message);
}

// Exceptions
class ServerException implements Exception {
  final String message;
  ServerException(String rawMessage) : message = _cleanErrorMessage(rawMessage);
  @override
  String toString() => message;
}

class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException(String rawMessage)
    : message = _cleanErrorMessage(rawMessage);
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  CacheException(String rawMessage) : message = _cleanErrorMessage(rawMessage);
  @override
  String toString() => message;
}

String _cleanErrorMessage(String message) {
  String textToParse = message;

  if (textToParse.startsWith('Exception: ')) {
    textToParse = textToParse.replaceFirst('Exception: ', '');
  }

  // 1. Try to decode the whole message as JSON
  try {
    final decoded = jsonDecode(textToParse);
    if (decoded is Map) {
      if (decoded.containsKey('exception')) {
        return _formatExceptionText(decoded['exception'].toString());
      }
      if (decoded.containsKey('message')) {
        return _formatExceptionText(decoded['message'].toString());
      }
    }
  } catch (_) {}

  // 2. Try to extract a JSON substring if there is one
  try {
    final jsonRegex = RegExp(r'\{.*\}');
    final match = jsonRegex.firstMatch(textToParse);
    if (match != null) {
      final jsonPart = match.group(0)!;
      final decoded = jsonDecode(jsonPart);
      if (decoded is Map) {
        if (decoded.containsKey('exception')) {
          return _formatExceptionText(decoded['exception'].toString());
        }
        if (decoded.containsKey('message')) {
          return _formatExceptionText(decoded['message'].toString());
        }
      }
    }
  } catch (_) {}

  // 3. Fallback: format the raw text
  return _formatExceptionText(textToParse);
}

String _formatExceptionText(String text) {
  String clean = text;

  // Strip Python exception class name prefix if present
  final pythonExceptionRegex = RegExp(r'^[a-zA-Z0-9_\.]+(Error|Exception):\s*');
  if (pythonExceptionRegex.hasMatch(clean)) {
    clean = clean.replaceFirst(pythonExceptionRegex, '');
  }

  // Also strip any other internal/nested class names
  final internalExceptionRegex = RegExp(
    r'[a-zA-Z0-9_\.]+(Error|Exception):\s*',
  );
  clean = clean.replaceAll(internalExceptionRegex, '');

  // Strip HTML tags like <strong>, </strong>, etc.
  clean = clean.replaceAll(RegExp(r'<[^>]*>'), '');

  // Clean up escaped newlines/quotes and trim
  clean = clean.replaceAll(r'\n', '\n').replaceAll(r'\"', '"').trim();

  return clean;
}
