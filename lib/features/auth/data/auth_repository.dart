import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/auth/pkce.dart';
import '../../../core/auth/token_storage.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/settings/app_preferences.dart';
import '../../../shared/models/identity_provider.dart';
import '../../../shared/models/user.dart';

class LoginOptions {
  const LoginOptions({
    this.usernameEnabled = true,
    this.emailEnabled = true,
    this.emailRegistrationEnabled = false,
    this.emailVerificationEnabled = false,
    this.passwordResetEnabled = false,
    this.turnstileRegistrationEnabled = false,
    this.turnstileSiteKey = '',
    this.providers = const [],
  });

  final bool usernameEnabled;
  final bool emailEnabled;
  final bool emailRegistrationEnabled;
  final bool emailVerificationEnabled;
  final bool passwordResetEnabled;
  final bool turnstileRegistrationEnabled;
  final String turnstileSiteKey;
  final List<IdentityProvider> providers;

  factory LoginOptions.fromApi(Map<String, dynamic> json) {
    final providers =
        (json['providers'] is List ? json['providers'] as List : const [])
            .whereType<Map>()
            .map((e) => IdentityProvider.fromApi(Map<String, dynamic>.from(e)))
            .where((p) => p.loginEnabled && p.slug.isNotEmpty)
            .toList();
    return LoginOptions(
      usernameEnabled: json['usernameEnabled'] != false,
      emailEnabled: json['emailEnabled'] != false,
      emailRegistrationEnabled: json['emailRegistrationEnabled'] == true,
      emailVerificationEnabled: json['emailVerificationEnabled'] == true,
      passwordResetEnabled: json['passwordResetEnabled'] == true,
      turnstileRegistrationEnabled:
          json['turnstileRegistrationEnabled'] == true,
      turnstileSiteKey: '${json['turnstileSiteKey'] ?? ''}',
      providers: providers,
    );
  }
}

/// Intermediate login result — either fully authenticated or needs 2FA.
class LoginResult {
  const LoginResult.authenticated(this.user)
    : twoFactorRequired = false,
      challengeToken = null,
      verificationMethods = const [];

  const LoginResult.needsTwoFactor({
    required this.challengeToken,
    required this.verificationMethods,
  }) : twoFactorRequired = true,
       user = null;

  final bool twoFactorRequired;
  final String? challengeToken;
  final List<String> verificationMethods;
  final User? user;
}

class AuthRepository {
  AuthRepository({
    required this.baseUrl,
    required this._dio,
    required this._tokenStorage,
  });

  /// Configured API origin (no `/api/v1`), used to build browser SSO URLs.
  final String baseUrl;
  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<LoginOptions> loginOptions() async {
    try {
      final response = await _dio.get(ApiEndpoints.loginOptions);
      final data = ApiEnvelope.unwrapMap(response);
      return LoginOptions.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// OAuth/OIDC login via system browser (flutter_web_auth_2 + PKCE).
  ///
  /// Callback scheme must match platform config: `deeix://auth/callback`.
  Future<LoginResult> loginWithProvider(IdentityProvider provider) async {
    try {
      final pkce = PkcePair.generate();
      const callbackScheme = 'deeix';
      const redirectUri = 'deeix://auth/callback';
      final startUri =
          Uri.parse(
            '$baseUrl${AppConfig.apiPrefix}'
            '${ApiEndpoints.providerStart(provider.slug)}',
          ).replace(
            queryParameters: {
              'redirect_uri': redirectUri,
              'code_challenge': pkce.challenge,
              'code_challenge_method': 'S256',
              'intent': 'login',
            },
          );

      final result = await FlutterWebAuth2.authenticate(
        url: startUri.toString(),
        callbackUrlScheme: callbackScheme,
      );
      final returned = Uri.parse(result);
      final code = returned.queryParameters['code'];
      final state = returned.queryParameters['state'];
      if (code == null || code.isEmpty) {
        throw ApiException(message: 'SSO 未返回授权码');
      }

      final response = await _dio.post(
        ApiEndpoints.providerCallback(provider.slug),
        data: {
          'code': code,
          'state': state,
          'redirectURI': redirectUri,
          'codeVerifier': pkce.verifier,
          'intent': 'login',
        },
      );
      return _applyLoginData(ApiEnvelope.unwrapMap(response));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'SSO 登录失败: $e');
    }
  }

  Future<LoginResult> _applyLoginData(Map<String, dynamic> data) async {
    if (data['twoFactorRequired'] == true) {
      final methods = (data['verificationMethods'] is List)
          ? (data['verificationMethods'] as List).map((e) => '$e').toList()
          : <String>['two_factor'];
      return LoginResult.needsTwoFactor(
        challengeToken: '${data['twoFactorChallengeToken'] ?? ''}',
        verificationMethods: methods.isEmpty ? ['two_factor'] : methods,
      );
    }
    final token = data['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException(message: '登录成功但未返回 accessToken');
    }
    await _tokenStorage.saveAccessToken(token);
    final userMap = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;
    return LoginResult.authenticated(User.fromApi(userMap));
  }

  Future<LoginResult> login({
    required String account,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'username': account.trim(), 'password': password},
      );
      final data = ApiEnvelope.unwrapMap(response);
      return _applyLoginData(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Complete 2FA after login (web: POST /auth/2fa/verify).
  Future<User> verifyTwoFactor({
    required String challengeToken,
    required String code,
    String verificationMethod = 'two_factor',
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.twoFactorVerify,
        data: {
          'challengeToken': challengeToken,
          'verificationMethod': verificationMethod,
          'code': code.trim(),
        },
      );
      final data = ApiEnvelope.unwrapMap(response);
      final token =
          data['accessToken'] as String? ??
          AuthInterceptor.extractAccessToken(response.data);
      if (token == null || token.isEmpty) {
        throw ApiException(message: '2FA 成功但未返回 accessToken');
      }
      await _tokenStorage.saveAccessToken(token);
      final userMap = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : data;
      return User.fromApi(userMap);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> startTwoFactorEmail({required String challengeToken}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.twoFactorEmailStart,
        data: {'challengeToken': challengeToken},
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> registerEmailStart({required String email}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registerEmailStart,
        data: {'email': email.trim()},
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<User> registerEmailComplete({
    required String email,
    required String password,
    String? code,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registerEmailComplete,
        data: {'email': email.trim(), 'password': password, 'code': ?code},
      );
      final data = ApiEnvelope.unwrapMap(response);
      final token =
          data['accessToken'] as String? ??
          AuthInterceptor.extractAccessToken(response.data);
      if (token != null && token.isNotEmpty) {
        await _tokenStorage.saveAccessToken(token);
        if (data['user'] is Map) {
          return User.fromApi(Map<String, dynamic>.from(data['user'] as Map));
        }
        return User.fromApi(data);
      }
      final loginResult = await login(account: email, password: password);
      if (loginResult.user != null) return loginResult.user!;
      throw ApiException(message: '注册完成，请登录');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> passwordResetStart({required String email}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.passwordResetStart,
        data: {'email': email.trim()},
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> passwordResetComplete({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.passwordResetComplete,
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Start signed-in password change (web client path).
  Future<Map<String, dynamic>> passwordChangeStart({
    String? verificationMethod,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.passwordChangeStart,
        data: {'verificationMethod': ?verificationMethod},
      );
      return ApiEnvelope.unwrapMap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> passwordChangeComplete(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.passwordChangeComplete,
        data: body,
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<User> patchMe({
    String? displayName,
    String? avatarURL,
    String? locale,
    String? timezone,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.me,
        data: {
          'displayName': ?displayName,
          'avatarURL': ?avatarURL,
          'locale': ?locale,
          'timezone': ?timezone,
        },
      );
      final data = ApiEnvelope.unwrapMap(response);
      return User.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<User?> currentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      if (response.statusCode == 401 || response.statusCode == 403) {
        return null;
      }
      final data = ApiEnvelope.unwrapMap(response);
      return User.fromApi(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    } on ApiException catch (e) {
      if (e.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<User?> tryRestoreSession() async {
    await _tokenStorage.load();
    if (_tokenStorage.accessToken != null) {
      final user = await currentUser();
      if (user != null) return user;
    }
    try {
      final response = await _dio.post(ApiEndpoints.refresh);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = ApiEnvelope.unwrapMap(response);
        final token =
            data['accessToken'] as String? ??
            AuthInterceptor.extractAccessToken(response.data);
        if (token != null && token.isNotEmpty) {
          await _tokenStorage.saveAccessToken(token);
        }
        return currentUser();
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final dio = await ref.watch(dioReadyProvider.future);
  final storage = ref.watch(tokenStorageProvider);
  final baseUrl = ref.watch(serverBaseUrlProvider);
  return AuthRepository(dio: dio, tokenStorage: storage, baseUrl: baseUrl);
});

final loginOptionsProvider = FutureProvider<LoginOptions>((ref) async {
  final repo = await ref.watch(authRepositoryProvider.future);
  return repo.loginOptions();
});
