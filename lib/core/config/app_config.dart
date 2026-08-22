import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// App name shown in UI.
  static const String appName = 'ConstructionMS';

  /// App version shown in UI.
  static const String appVersion = '1.0.0';

  /// Android/iOS package identifier.
  static const String packageName = 'com.constructionms.app';

  /// Home screen layout mode. Allowed values: 'list' or 'folder'.
  static const String homeScreenLayout = 'list';

  // / Frappe server base URL (with trailing slash)
  static String get baseUrl => dotenv.get(
    'BASE_URL',
    fallback: 'https://uat-aaryaconstructions.frappe.cloud/',
  );

  // / Frappe server base URL (with trailing slash)
  // static String get baseUrl => dotenv.get(
  //   'BASE_URL',
  //   fallback: 'https://erpaaryaconstruction.m.frappe.cloud/',
  // );

  // static String get baseUrl => dotenv.get(
  //   'BASE_URL',
  //   fallback: 'https://construction-management.quantcloud.in/',
  // );

  /// OAuth client ID from Frappe OAuth Client settings
  static String get oauthClientId =>
      dotenv.get('OAUTH_CLIENT_ID', fallback: 'your_oauth_client_id');

  /// OAuth client secret from Frappe OAuth Client settings
  static String get oauthClientSecret =>
      dotenv.get('OAUTH_CLIENT_SECRET', fallback: 'your_oauth_client_secret');
}
