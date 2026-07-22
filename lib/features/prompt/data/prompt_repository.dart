import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/prompt_preset.dart';

class PromptRepository {
  PromptRepository(this._dio);
  final Dio _dio;

  Future<List<PromptPreset>> list({String? query}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.promptPresets,
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          'page': 1,
          'page_size': 100,
        },
      );
      final data = ApiEnvelope.unwrapMap(response);
      final results = data['results'] is List
          ? data['results'] as List
          : const [];
      return results
          .whereType<Map>()
          .map((e) => PromptPreset.fromApi(Map<String, dynamic>.from(e)))
          .where((p) => p.enabled && p.content.isNotEmpty)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final promptRepositoryProvider = FutureProvider<PromptRepository>((ref) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return PromptRepository(dio);
});

final promptPresetsProvider = FutureProvider<List<PromptPreset>>((ref) async {
  final repo = await ref.watch(promptRepositoryProvider.future);
  return repo.list();
});
