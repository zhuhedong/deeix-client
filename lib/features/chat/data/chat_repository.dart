import 'dart:async';

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

/// Media generation task kind.
enum MediaKind { image, video }

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
    List<String>? knowledgeBaseIds,
    CancelToken? cancelToken,
  }) {
    return postNdjson(
      ApiEndpoints.conversationMessageStream(conversationPublicId),
      {
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
        if (knowledgeBaseIds != null && knowledgeBaseIds.isNotEmpty)
          'knowledgeBaseIDs': knowledgeBaseIds,
      },
      cancelToken: cancelToken,
    );
  }

  /// POST /conversations/{id}/media/{images|videos}/generations/stream
  /// (DEEIX-Chat 0.4.4+). Same NDJSON protocol as [streamMessage]; the final
  /// `completed` assistant message carries the generated media attachments.
  Stream<StreamChunk> streamMediaGeneration({
    required String conversationPublicId,
    required MediaKind kind,
    required String prompt,
    String? model,
    List<String>? fileIds,
    String? clientRunId,
    String? parentMessagePublicID,
    CancelToken? cancelToken,
  }) {
    final path = kind == MediaKind.video
        ? ApiEndpoints.mediaVideoGenerationStream(conversationPublicId)
        : (fileIds != null && fileIds.isNotEmpty)
        ? ApiEndpoints.mediaImageEditStream(conversationPublicId)
        : ApiEndpoints.mediaImageGenerationStream(conversationPublicId);
    return postNdjson(path, {
      'prompt': prompt,
      'model': ?model,
      if (fileIds != null && fileIds.isNotEmpty) 'fileIDs': fileIds,
      'clientRunID': ?clientRunId,
      'parentMessagePublicID': ?parentMessagePublicID,
    }, cancelToken: cancelToken);
  }

  /// POST /temporary-chat/messages/stream (DEEIX-Chat 0.4.4+).
  /// Nothing is persisted server-side; the full history is sent each turn.
  Stream<StreamChunk> streamTemporaryChat({
    required String sessionId,
    required String clientRunId,
    required String model,
    required List<({String role, String content})> messages,
    Map<String, dynamic>? options,
    List<String>? knowledgeBaseIds,
    CancelToken? cancelToken,
  }) {
    return postNdjson(ApiEndpoints.temporaryChatStream, {
      'sessionID': sessionId,
      'clientRunID': clientRunId,
      'model': model,
      'messages': [
        for (final m in messages) {'role': m.role, 'content': m.content},
      ],
      if (options != null && options.isNotEmpty) 'options': options,
      if (knowledgeBaseIds != null && knowledgeBaseIds.isNotEmpty)
        'knowledgeBaseIDs': knowledgeBaseIds,
    }, cancelToken: cancelToken);
  }

  /// Shared NDJSON POST: maps events to [StreamChunk]s and surfaces the
  /// server's error message for non-2xx responses.
  Stream<StreamChunk> postNdjson(
    String path,
    Map<String, dynamic> body, {
    CancelToken? cancelToken,
  }) async* {
    Response<ResponseBody> response;
    try {
      response = await _dio.post<ResponseBody>(
        path,
        data: body,
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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      throw await apiExceptionFromStreamError(e);
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
