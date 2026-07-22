import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the short-lived access token.
///
/// Refresh token is expected to live in HttpOnly cookies managed by
/// [CookieJar] (same as the web client). Access token is kept here so
/// cold starts can restore a session without re-login when refresh works.
///
/// All platform reads/writes are timeout-guarded: `flutter_secure_storage`
/// can occasionally stall on Android cold starts, and this must never block
/// app startup. If secure storage is unavailable we simply fall back to the
/// cookie-based refresh flow (which re-issues an access token anyway).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'deeix_access_token';
  static const _ioTimeout = Duration(seconds: 5);

  final FlutterSecureStorage _storage;

  /// In-memory cache to avoid async storage on every request.
  String? _memoryAccessToken;

  String? get accessToken => _memoryAccessToken;

  Future<void> load() async {
    try {
      _memoryAccessToken = await _storage
          .read(key: _accessTokenKey)
          .timeout(_ioTimeout);
    } catch (_) {
      // Secure storage slow/unavailable — keep any in-memory value and let the
      // cookie-based refresh restore the session instead of hanging startup.
    }
  }

  Future<void> saveAccessToken(String token) async {
    // Update memory first so in-flight requests can use it immediately, then
    // persist in the background — never block callers on a slow encrypted write.
    _memoryAccessToken = token;
    _storage
        .write(key: _accessTokenKey, value: token)
        .timeout(_ioTimeout)
        .ignore();
  }

  Future<void> clear() async {
    _memoryAccessToken = null;
    try {
      await _storage.delete(key: _accessTokenKey).timeout(_ioTimeout);
    } catch (_) {
      // Ignore — memory is already cleared.
    }
  }

  /// Prefer memory-only for pure short-lived tokens after login.
  void setMemoryAccessToken(String? token) {
    _memoryAccessToken = token;
  }
}
