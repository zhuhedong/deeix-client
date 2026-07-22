import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/project.dart';

class ProjectRepository {
  ProjectRepository(this._dio);
  final Dio _dio;

  Future<List<ConversationProject>> list({String status = 'active'}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.conversationProjects,
        queryParameters: {'status': status},
      );
      final data = ApiEnvelope.unwrap(response);
      final list = data is List
          ? data
          : (data is Map && data['results'] is List)
          ? data['results'] as List
          : const [];
      return list
          .whereType<Map>()
          .map((e) => ConversationProject.fromApi(Map<String, dynamic>.from(e)))
          .where((p) => p.publicID.isNotEmpty)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConversationProject> create({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.conversationProjects,
        data: {'name': name, 'description': ?description},
      );
      final data = ApiEnvelope.unwrapMap(response);
      return ConversationProject.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String publicId) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.conversationProjectById(publicId),
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> assignConversation({
    required String conversationPublicId,
    String? projectId,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.conversationProject(conversationPublicId),
        data: {'projectID': projectId},
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final projectRepositoryProvider = FutureProvider<ProjectRepository>((
  ref,
) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return ProjectRepository(dio);
});
