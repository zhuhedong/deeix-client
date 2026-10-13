import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../auth/token_storage.dart';
import '../constants/app_config.dart';
import '../settings/app_preferences.dart';
import 'auth_interceptor.dart';

/// Bumped whenever the access token is rejected and cannot be refreshed, so
/// the auth controller can send the user back to the login screen instead of
/// leaving every screen failing with 401.
class AuthExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void signal() => state++;
}

final authExpiredProvider = NotifierProvider<AuthExpiredNotifier, int>(
  AuthExpiredNotifier.new,
);

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final cookieJarProvider = FutureProvider<CookieJar>((ref) async {
  final dir = await getApplicationSupportDirectory();
  final cookiePath = '${dir.path}/${AppConfig.cookieDirName}';
  await Directory(cookiePath).create(recursive: true);
  return PersistCookieJar(
    ignoreExpires: false,
    storage: FileStorage(cookiePath),
  );
});

/// Shared Dio instance with cookie jar + auth interceptor.
///
/// Await [dioReadyProvider] before first network call so cookies load.
final dioProvider = Provider<Dio>((ref) {
  throw UnimplementedError(
    'Use dioReadyProvider; Dio must be initialized with cookie jar.',
  );
});

final dioReadyProvider = FutureProvider<Dio>((ref) async {
  // Rebuilds whenever the user changes the server address.
  final baseUrl = ref.watch(serverBaseUrlProvider);
  final cookieJar = await ref.watch(cookieJarProvider.future);
  final tokenStorage = ref.watch(tokenStorageProvider);
  await tokenStorage.load();

  final dio = Dio(
    BaseOptions(
      baseUrl: '$baseUrl${AppConfig.apiPrefix}',
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      // Only 2xx are success so AuthInterceptor can catch 401 and refresh.
      // Error body is still available on DioException.response.
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );

  dio.interceptors.add(CookieManager(cookieJar));
  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenStorage: tokenStorage,
      onAuthFailure: () => ref.read(authExpiredProvider.notifier).signal(),
    ),
  );

  // Helpful during development; strip for release if noisy.
  assert(() {
    dio.interceptors.add(
      // Never log request bodies: they contain passwords / 2FA codes /
      // API keys even in debug builds.
      LogInterceptor(requestBody: false, responseBody: false, error: true),
    );
    return true;
  }());

  return dio;
});
