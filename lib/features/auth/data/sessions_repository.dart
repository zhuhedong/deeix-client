import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/session.dart';

class SessionsRepository {
  SessionsRepository(this._dio);
  final Dio _dio;

  Future<List<ActiveSession>> list() async {
    try {
      final response = await _dio.get(ApiEndpoints.sessions);
      final data = ApiEnvelope.unwrapMap(response);
      final results = data['results'] is List
          ? data['results'] as List
          : const [];
      return results
          .whereType<Map>()
          .map((e) => ActiveSession.fromApi(Map<String, dynamic>.from(e)))
          .where((s) => s.sessionID.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logoutSession(String sessionId) async {
    try {
      final response = await _dio.post(ApiEndpoints.sessionLogout(sessionId));
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logoutAll() async {
    try {
      final response = await _dio.post(ApiEndpoints.logoutAll);
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final sessionsRepositoryProvider = FutureProvider<SessionsRepository>((
  ref,
) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return SessionsRepository(dio);
});
