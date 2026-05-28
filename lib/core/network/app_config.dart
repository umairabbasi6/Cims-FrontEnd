/// API base URL and auth paths (single source of truth for networking).
class AppConfig {
  AppConfig._();

  // Default API base URL for local development on web.
  // - Web (chrome): use 127.0.0.1 or localhost (this is the most common setup).
  // - Android emulator: use 10.0.2.2 if testing on emulator (not web).
  // You can override this at build/run time with --dart-define=API_BASE_URL=<url>.
  static const String _defaultBase = 'http://127.0.0.1:8000/api';

  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBase);

  /// Login (username/password).
  static const String authLoginPath = '/auth/login';

  /// Refresh access token; body uses [refreshTokenBodyKey] by default.
  static const String authRefreshPath = '/auth/refresh';

  /// JSON field sent in refresh request (matches login response `refresh_token`).
  static const String refreshTokenBodyKey = 'refresh_token';
}
