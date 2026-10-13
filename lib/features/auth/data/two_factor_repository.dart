import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';

class TwoFactorStatus {
  const TwoFactorStatus({
    this.available = false,
    this.totpEnabled = false,
    this.required = false,
    this.recoveryCount = 0,
  });

  final bool available;
  final bool totpEnabled;
  final bool required;
  final int recoveryCount;

  factory TwoFactorStatus.fromApi(Map<String, dynamic> json) => TwoFactorStatus(
    available: json['available'] == true,
    totpEnabled: json['totpEnabled'] == true,
    required: json['required'] == true,
    recoveryCount: json['recoveryCount'] is int
        ? json['recoveryCount'] as int
        : 0,
  );
}

class TwoFactorSetup {
  const TwoFactorSetup({required this.secret, required this.otpauthURL});
  final String secret;
  final String otpauthURL;
}

/// Account two-factor (TOTP) management (DEEIX-Chat 0.4.4+).
class TwoFactorRepository {
  TwoFactorRepository(this._dio);

  final Dio _dio;

  Future<TwoFactorStatus> status() async {
    try {
      final response = await _dio.get(ApiEndpoints.twoFactorStatus);
      return TwoFactorStatus.fromApi(ApiEnvelope.unwrapMap(response));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TwoFactorSetup> startSetup() async {
    try {
      final response = await _dio.post(ApiEndpoints.twoFactorSetupStart);
      final data = ApiEnvelope.unwrapMap(response);
      return TwoFactorSetup(
        secret: '${data['secret'] ?? ''}',
        otpauthURL: '${data['otpauthURL'] ?? ''}',
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> cancelSetup() async {
    try {
      ApiEnvelope.unwrap(await _dio.delete(ApiEndpoints.twoFactorSetup));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Returns the one-time recovery codes.
  Future<List<String>> confirmSetup(String code) =>
      _codes(ApiEndpoints.twoFactorSetupConfirm, code);

  /// Returns fresh recovery codes (old ones stop working).
  Future<List<String>> regenerateRecoveryCodes(String code) =>
      _codes(ApiEndpoints.twoFactorRecoveryRegenerate, code);

  Future<void> disable(String code) async {
    try {
      ApiEnvelope.unwrap(
        await _dio.post(
          ApiEndpoints.twoFactorDisable,
          data: {'code': code.trim()},
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<String>> _codes(String path, String code) async {
    try {
      final response = await _dio.post(path, data: {'code': code.trim()});
      final data = ApiEnvelope.unwrapMap(response);
      return (data['recoveryCodes'] is List
              ? data['recoveryCodes'] as List
              : const [])
          .map((e) => '$e')
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final twoFactorRepositoryProvider = FutureProvider<TwoFactorRepository>((
  ref,
) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return TwoFactorRepository(dio);
});
