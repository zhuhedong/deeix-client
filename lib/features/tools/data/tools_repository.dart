import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/models/mcp_tool.dart';

class ToolsRepository {
  ToolsRepository(this._dio);
  final Dio _dio;

  Future<List<McpTool>> list() async {
    try {
      final response = await _dio.get(ApiEndpoints.mcpTools);
      final data = ApiEnvelope.unwrap(response);
      List list;
      if (data is Map && data['results'] is List) {
        list = data['results'] as List;
      } else if (data is List) {
        list = data;
      } else {
        list = const [];
      }
      return list
          .whereType<Map>()
          .map((e) => McpTool.fromApi(Map<String, dynamic>.from(e)))
          .where((t) => t.id > 0)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final toolsRepositoryProvider = FutureProvider<ToolsRepository>((ref) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return ToolsRepository(dio);
});

final mcpToolsProvider = FutureProvider<List<McpTool>>((ref) async {
  final repo = await ref.watch(toolsRepositoryProvider.future);
  return repo.list();
});
