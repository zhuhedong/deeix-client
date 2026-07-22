import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/ndjson_stream.dart';
import '../../../core/utils/stream_events.dart';
import '../../../shared/models/message.dart';

export '../../../core/utils/export_transcript.dart' show messagesToMarkdown;
export '../../../core/utils/stream_events.dart'
    show StreamChunk, messageFeedbackBody;

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  /// GET /conversations/{id}/messages?page=&page_size=
  Future<({List<ChatMessage> results, int total})> listMessagesPage(
    String conversationPublicId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.conversationMessages(conversationPublicId),
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final data = ApiEnvelope.unwrapMap(response);
      final items =
          (data['results'] is List ? data['results'] as List : const [])
              .whereType<Map>()
              .map((e) => ChatMessage.fromApi(Map<String, dynamic>.from(e)))
              .toList();
      final total = data['total'] is int
          ? data['total'] as int
          : int.tryParse('${data['total'] ?? items.length}') ?? items.length;
      return (results: items, total: total);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ChatMessage>> listMessages(
    String conversationPublicId, {
    int page = 1,
    int pageSize = 100,
  }) async {
    final pageData = await listMessagesPage(
      conversationPublicId,
      page: page,
      pageSize: pageSize,
    );
    return pageData.results;
  }

  /// POST /conversations/{id}/messages/stream
  Stream<StreamChunk> streamMessage({
    required String conversationPublicId,
    required String content,
    String contentType = 'text',
    String? model,
    List<String>? fileIds,
    String? clientRunId,
    String? branchReason,
    String? parentMessagePublicID,
    String? sourceMessagePublicID,
    Map<String, dynamic>? options,
    List<int>? selectedToolIds,
    CancelToken? cancelToken,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      ApiEndpoints.conversationMessageStream(conversationPublicId),
      data: {
        'content': content,
        'contentType': contentType,
        'model': ?model,
        if (fileIds != null && fileIds.isNotEmpty) 'fileIDs': fileIds,
        'clientRunID': ?clientRunId,
        'branchReason': ?branchReason,
        'parentMessagePublicID': ?parentMessagePublicID,
        'sourceMessagePublicID': ?sourceMessagePublicID,
        if (options != null && options.isNotEmpty) 'options': options,
        if (selectedToolIds != null && selectedToolIds.isNotEmpty)
          'selectedToolIDs': selectedToolIds,
      },
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: AppConfig.streamReceiveTimeout,
        headers: {
          'Accept': 'application/x-ndjson, application/json, */*',
          'Content-Type': 'application/json',
        },
      ),
      cancelToken: cancelToken,
    );

    final status = response.statusCode ?? 0;
    if (status >= 400) {
      final body = response.data;
      var msg = '流式请求失败 ($status)';
      if (body != null) {
        try {
          final bytes = await body.stream.fold<List<int>>(
            <int>[],
            (p, e) => p..addAll(e),
          );
          final text = utf8.decode(bytes, allowMalformed: true);
          final decoded = jsonDecode(text);
          msg = ApiEnvelope.errorMsgOf(decoded) ?? text;
        } catch (_) {}
      }
      throw ApiException(message: msg, statusCode: status);
    }

    final byteStream = response.data?.stream;
    if (byteStream == null) {
      yield const StreamChunk(done: true, error: 'stream body is empty');
      return;
    }

    final parser = NdjsonObjectStream();
    await for (final event in parser.parse(byteStream)) {
      final chunk = mapStreamEvent(event);
      yield chunk;
      if (chunk.done) return;
    }

    yield const StreamChunk(done: true);
  }

  Future<void> cancelRun(String runId) async {
    try {
      final response = await _dio.post(ApiEndpoints.runCancel(runId));
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> setFeedback(String messagePublicId, String? feedback) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.messageFeedback(messagePublicId),
        data: messageFeedbackBody(feedback),
      );
      ApiEnvelope.unwrap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ChatMessage> updateMessageContent(
    String messagePublicId,
    String content,
  ) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.message(messagePublicId),
        data: {'content': content},
      );
      final data = ApiEnvelope.unwrapMap(response);
      return ChatMessage.fromApi(data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /conversations/{id}/export — full JSON export payload.
  Future<Map<String, dynamic>> exportConversation(
    String conversationPublicId,
  ) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.conversationExport(conversationPublicId),
      );
      return ApiEnvelope.unwrapMap(response);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final chatRepositoryProvider = FutureProvider<ChatRepository>((ref) async {
  final dio = await ref.watch(dioReadyProvider.future);
  return ChatRepository(dio);
});
