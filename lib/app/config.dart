class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'DAILY_KATHA_API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );
}
