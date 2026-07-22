import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/conversation.dart';
import '../../../shared/models/conversation_share.dart';

class ConversationPage {
  const ConversationPage({required this.results, required this.total});

  final List<Conversation> results;
  final int total;
}

class ConversationRepository {
  ConversationRepository(this._dio);

  final Dio _dio;

  /// GET /conversations?page=&page_size=&status=&q=
  Future<ConversationPage> listPage({
    int page = 1,
    int pageSize = 30,
    String status = 'active',
    String? query,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.conversations,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'status': status,
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        },
      );
      final data = ApiEnvelope.unwrapMap(response);
      final results =
          (data['results'] is List ? data['results'] as List : const [])
              .whereType<Map>()
              .map((e) => Conversation.fromApi(Map<String, dynamic>.from(e)))
              .where((c) => c.publicID.isNotEmpty)
              .toList();
      final total = data['total'] is int
          ? data['total'] as int
          : int.tryParse('${data['total'] ?? results.length}') ??
                results.length;
      return ConversationPage(results: results, total: total);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Conversation>> list({
    int page = 1,
    int pageSize = 50,
    String status = 'active',
  }) async {
    final pageData = await listPage(
      page: page,
      pageSize: pageSize,
      status: status,
    );
    return pageData.results;
  }

  Future<Conversation> create({String? title, String? model}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.conversations,
        data: {'title': ?title, 'model': ?model},
      );
      final data = ApiEnvelope.unwrapMap(response);
      return Conversation.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String publicId) async {
    try {
      final response = await _dio.delete(ApiEndpoints.conversation(publicId));
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Conversation> rename(String publicId, String title) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.conversationTitle(publicId),
        data: {'title': title},
      );
      final data = ApiEnvelope.unwrapMap(response);
      return Conversation.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Conversation> setStarred(String publicId, bool starred) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.conversationStar(publicId),
        data: {'starred': starred},
      );
      final data = ApiEnvelope.unwrapMap(response);
      return Conversation.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Conversation> setArchived(String publicId, bool archived) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.conversationArchive(publicId),
        data: {'archived': archived},
      );
      final data = ApiEnvelope.unwrapMap(response);
      return Conversation.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Conversation> getById(String publicId) async {
    try {
      final response = await _dio.get(ApiEndpoints.conversation(publicId));
      final data = ApiEnvelope.unwrapMap(response);
      return Conversation.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConversationShare> getShare(String publicId) async {
    try {
      final response = await _dio.get(ApiEndpoints.conversationShare(publicId));
      final data = ApiEnvelope.unwrapMap(response);
      return ConversationShare.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConversationShare> createShare(String publicId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.conversationShare(publicId),
        data: <String, dynamic>{},
      );
      final data = ApiEnvelope.unwrapMap(response);
      return ConversationShare.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> revokeShare(String publicId) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.conversationShare(publicId),
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> export(String publicId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.conversationExport(publicId),
      );
      return ApiEnvelope.unwrapMap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> setProject(String publicId, String? projectId) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.conversationProject(publicId),
        data: {'projectID': projectId},
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final conversationRepositoryProvider = FutureProvider<ConversationRepository>((
  ref,
) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return ConversationRepository(dio);
});
