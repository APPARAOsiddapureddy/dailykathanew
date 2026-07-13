class AppConfig {
  const AppConfig._();

  // TEMPORARY: default points at the local backend for development.
  // Switch back to https://daily-katha-cms.onrender.com before building
  // any release (or pass --dart-define=API_BASE_URL=...).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );
}
