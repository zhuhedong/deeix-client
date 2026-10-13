import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/model_provider.dart';

/// Personal model providers API (DEEIX-Chat 0.4.4+).
///
/// The API key is only ever sent to the user's own DEEIX server; the server
/// returns a masked `keyHint` afterwards.
class ModelProviderRepository {
  ModelProviderRepository(this._dio);

  final Dio _dio;

  Future<ModelProviderAccess> access() async {
    try {
      final response = await _dio.get(ApiEndpoints.modelProvidersAccess);
      return ModelProviderAccess.fromApi(ApiEnvelope.unwrapMap(response));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ModelProvider>> list() async {
    try {
      final response = await _dio.get(ApiEndpoints.modelProviders);
      final data = ApiEnvelope.unwrapMap(response);
      return (data['providers'] is List ? data['providers'] as List : const [])
          .whereType<Map>()
          .map((e) => ModelProvider.fromApi(Map<String, dynamic>.from(e)))
          .where((p) => p.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /me/model-providers/probe — checks the key and lists the upstream
  /// models without saving anything.
  Future<List<String>> probe({
    required String protocol,
    required String baseURL,
    required String apiKey,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.modelProvidersProbe,
        data: {
          'protocol': protocol,
          'baseURL': baseURL.trim(),
          'apiKey': apiKey.trim(),
        },
      );
      return _modelNames(ApiEnvelope.unwrapMap(response));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ModelProvider> create({
    required String protocol,
    required String baseURL,
    required String apiKey,
    String? name,
    List<String> models = const [],
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.modelProviders,
        data: {
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
          'protocol': protocol,
          'baseURL': baseURL.trim(),
          'apiKey': apiKey.trim(),
          'models': models,
          'source': 'manual',
        },
      );
      return _provider(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ModelProvider> update(
    String id, {
    String? name,
    String? apiKey,
    List<String>? models,
    bool? enabled,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.modelProvider(id),
        data: {
          'name': ?name,
          if (apiKey != null && apiKey.trim().isNotEmpty)
            'apiKey': apiKey.trim(),
          'models': ?models,
          'enabled': ?enabled,
        },
      );
      return _provider(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      ApiEnvelope.unwrap(await _dio.delete(ApiEndpoints.modelProvider(id)));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /me/model-providers/{id}/models — refresh upstream model list.
  Future<List<String>> availableModels(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.modelProviderModels(id));
      return _modelNames(ApiEnvelope.unwrapMap(response));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static List<String> _modelNames(Map<String, dynamic> data) =>
      (data['models'] is List ? data['models'] as List : const [])
          .map((m) => m is Map ? '${m['name'] ?? ''}' : '$m')
          .where((m) => m.isNotEmpty)
          .toList();

  ModelProvider _provider(Response response) {
    final data = ApiEnvelope.unwrapMap(response);
    final map = data['provider'] is Map
        ? Map<String, dynamic>.from(data['provider'] as Map)
        : data;
    return ModelProvider.fromApi(map);
  }
}

final modelProviderRepositoryProvider = FutureProvider<ModelProviderRepository>(
  (ref) async {
    final dio = await ref.watch(dioReadyProvider.future);
    return ModelProviderRepository(dio);
  },
);
