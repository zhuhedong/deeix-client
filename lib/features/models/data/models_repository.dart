import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/llm_model.dart';

class ModelsRepository {
  ModelsRepository(this._dio);

  final Dio _dio;

  /// GET /models → data: PublicModelResponse[]
  Future<List<LlmModel>> list() async {
    try {
      final response = await _dio.get(ApiEndpoints.models);
      final data = ApiEnvelope.unwrap(response);
      final list = data is List
          ? data
          : (data is Map && data['results'] is List)
          ? data['results'] as List
          : const [];
      return list
          .whereType<Map>()
          .map((e) => LlmModel.fromApi(Map<String, dynamic>.from(e)))
          .where((m) => m.platformModelName.isNotEmpty)
          .toList()
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          if (byOrder != 0) return byOrder;
          return a.platformModelName.compareTo(b.platformModelName);
        });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final modelsRepositoryProvider = FutureProvider<ModelsRepository>((ref) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return ModelsRepository(dio);
});

final modelsListProvider = FutureProvider<List<LlmModel>>((ref) async {
  final repo = await ref.watch(modelsRepositoryProvider.future);
  return repo.list();
});
