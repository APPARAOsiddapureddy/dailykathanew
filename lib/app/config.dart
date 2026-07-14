class AppConfig {
  const AppConfig._();

  // Defaults to the deployed backend. For local development pass
  // --dart-define=API_BASE_URL=http://localhost:4000 (or your LAN IP).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://daily-katha-cms.onrender.com',
  );
}
