import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import 'api_endpoints.dart';

typedef OnAuthFailure = void Function();

/// Attaches Bearer access token and performs single-flight 401 refresh.
///
/// Compatible with DEEIX-Chat's web auth model:
/// - Access token in `Authorization` header
/// - Refresh token in HttpOnly cookie (CookieJar handles it)
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.tokenStorage,
    this.onAuthFailure,
  });

  final Dio dio;
  final TokenStorage tokenStorage;
  final OnAuthFailure? onAuthFailure;

  Completer<bool>? _refreshCompleter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    final isAuthEndpoint =
        path.contains(ApiEndpoints.login) ||
        path.contains(ApiEndpoints.refresh) ||
        path.contains(ApiEndpoints.registerEmailStart) ||
        path.contains(ApiEndpoints.registerEmailComplete) ||
        path.contains('/auth/');

    if (status != 401 || isAuthEndpoint) {
      return handler.next(err);
    }

    // Already retried once.
    if (err.requestOptions.extra['__retried'] == true) {
      await tokenStorage.clear();
      onAuthFailure?.call();
      return handler.next(err);
    }

    final refreshed = await _refreshToken();
    if (!refreshed) {
      await tokenStorage.clear();
      onAuthFailure?.call();
      return handler.next(err);
    }

    try {
      final opts = err.requestOptions;
      opts.extra['__retried'] = true;
      final token = tokenStorage.accessToken;
      if (token != null) {
        opts.headers['Authorization'] = 'Bearer $token';
      }
      final response = await dio.fetch(opts);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Future<bool> _refreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final response = await dio.post(
        ApiEndpoints.refresh,
        options: Options(extra: {'__skip_auth_retry': true}),
      );

      // RefreshTokenResponseDoc → data: LoginResponse { accessToken, ... }
      final token = extractAccessToken(response.data);
      if (token != null && token.isNotEmpty) {
        await tokenStorage.saveAccessToken(token);
        _refreshCompleter!.complete(true);
        return true;
      }

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        // Cookie rotated but no token body — still treat as success.
        _refreshCompleter!.complete(true);
        return true;
      }

      _refreshCompleter!.complete(false);
      return false;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Tolerant extraction: different DEEIX versions may nest the token.
  static String? extractAccessToken(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    for (final key in ['accessToken', 'access_token', 'token']) {
      final v = map[key];
      if (v is String && v.isNotEmpty) return v;
    }

    final nested = map['data'];
    if (nested is Map) {
      return extractAccessToken(nested);
    }
    return null;
  }
}
