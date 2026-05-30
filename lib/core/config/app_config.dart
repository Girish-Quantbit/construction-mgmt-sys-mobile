class AppConfig {
  /// App name shown in UI.
  static const String appName = 'ConstructionMS';

  /// App version shown in UI.
  static const String appVersion = '1.0.0';

  /// Android/iOS package identifier.
  static const String packageName = 'com.constructionms.app';

  /// Home screen layout mode. Allowed values: 'list' or 'folder'.
  static const String homeScreenLayout = 'list';

  /// Frappe server base URL (with trailing slash)
  /// TODO: Update with your Frappe server URL
  static const String baseUrl = 'https://uat-aaryaconstructions.frappe.cloud/';

  /// OAuth client ID from Frappe OAuth Client settings
  static const String oauthClientId = 'your_oauth_client_id';

  /// OAuth client secret from Frappe OAuth Client settings
  static const String oauthClientSecret = 'your_oauth_client_secret';
}
