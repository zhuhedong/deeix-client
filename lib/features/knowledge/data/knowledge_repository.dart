import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/knowledge_base.dart';

/// Knowledge bases API (DEEIX-Chat 0.4.4+).
class KnowledgeRepository {
  KnowledgeRepository(this._dio);

  final Dio _dio;

  /// GET /knowledge-bases — every knowledge base the user may use in chat
  /// (built-in + own).
  Future<List<KnowledgeBase>> listVisible() =>
      _list(ApiEndpoints.knowledgeBases);

  /// GET /knowledge-bases/mine — the user's own knowledge bases.
  Future<List<KnowledgeBase>> listMine() =>
      _list(ApiEndpoints.myKnowledgeBases);

  Future<List<KnowledgeBase>> _list(String path) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: {'page': 1, 'page_size': 100},
      );
      return ApiEnvelope.unwrapResults(response)
          .whereType<Map>()
          .map((e) => KnowledgeBase.fromApi(Map<String, dynamic>.from(e)))
          .where((k) => k.publicID.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<KnowledgeBase> create({
    required String name,
    String description = '',
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.myKnowledgeBases,
        data: {
          'name': name.trim(),
          if (description.trim().isNotEmpty) 'description': description.trim(),
        },
      );
      return _kb(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<KnowledgeBase> update(
    String id, {
    String? name,
    String? description,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.myKnowledgeBase(id),
        data: {'name': ?name?.trim(), 'description': ?description?.trim()},
      );
      return _kb(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      ApiEnvelope.unwrap(await _dio.delete(ApiEndpoints.myKnowledgeBase(id)));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /knowledge-bases/{id}/files
  Future<List<KnowledgeBaseFile>> listFiles(String id) =>
      _files(ApiEndpoints.knowledgeBaseFiles(id));

  /// GET /knowledge-bases/mine/{id}/available-files — uploaded files that can
  /// still be added to this knowledge base.
  Future<List<KnowledgeBaseFile>> listAvailableFiles(String id) =>
      _files(ApiEndpoints.myKnowledgeBaseAvailableFiles(id));

  Future<List<KnowledgeBaseFile>> _files(String path) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: {'page': 1, 'page_size': 100},
      );
      return ApiEnvelope.unwrapResults(response)
          .whereType<Map>()
          .map((e) => KnowledgeBaseFile.fromApi(Map<String, dynamic>.from(e)))
          .where((f) => f.fileID.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST /knowledge-bases/mine/{id}/files {fileIDs}
  Future<void> addFiles(String id, List<String> fileIds) async {
    if (fileIds.isEmpty) return;
    try {
      ApiEnvelope.unwrap(
        await _dio.post(
          ApiEndpoints.myKnowledgeBaseFiles(id),
          data: {'fileIDs': fileIds},
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> removeFile(String id, String fileId) async {
    try {
      ApiEnvelope.unwrap(
        await _dio.delete(ApiEndpoints.myKnowledgeBaseFile(id, fileId)),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  KnowledgeBase _kb(Response response) {
    final data = ApiEnvelope.unwrapMap(response);
    final map = data['knowledgeBase'] is Map
        ? Map<String, dynamic>.from(data['knowledgeBase'] as Map)
        : data;
    return KnowledgeBase.fromApi(map);
  }
}

final knowledgeRepositoryProvider = FutureProvider<KnowledgeRepository>((
  ref,
) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return KnowledgeRepository(dio);
});

/// Knowledge bases usable in chat (for the chat picker).
final visibleKnowledgeBasesProvider = FutureProvider<List<KnowledgeBase>>((
  ref,
) async {
  final repo = await ref.watch(knowledgeRepositoryProvider.future);
  return repo.listVisible();
});
