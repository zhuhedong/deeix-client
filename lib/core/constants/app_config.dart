/// Runtime configuration for the DEEIX native client.
///
/// Point [apiBaseUrl] at your deployed DEEIX-Chat public origin
/// (must be HTTPS in production). No backend code changes are required.
class AppConfig {
  AppConfig._();

  /// Public API origin, e.g. `https://vps.cli-help.com`
  /// Override at build time:
  /// `flutter run --dart-define=API_BASE_URL=https://your.domain`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vps.cli-help.com',
  );

  /// API path prefix used by DEEIX-Chat (Swagger basePath).
  static const String apiPrefix = '/api/v1';

  /// Connect / receive timeouts.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Stream endpoints may run much longer (NDJSON).
  static const Duration streamReceiveTimeout = Duration(minutes: 10);

  static const String appName = 'DEEIX';
  static const String cookieDirName = 'deeix_cookies';

  /// Swagger doc for this deployment.
  static const String swaggerDocUrl =
      'https://vps.cli-help.com/swagger/doc.json';
}
