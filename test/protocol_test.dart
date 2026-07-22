import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deeix_client/core/constants/app_config.dart';
import 'package:deeix_client/core/network/api_endpoints.dart';
import 'package:deeix_client/core/network/api_response.dart';
import 'package:deeix_client/core/utils/ndjson_stream.dart';
import 'package:deeix_client/core/utils/stream_events.dart';
import 'package:deeix_client/shared/models/conversation.dart';
import 'package:deeix_client/shared/models/message.dart';
import 'package:deeix_client/shared/models/message_attachment.dart';
import 'package:deeix_client/shared/models/user.dart';

void main() {
  group('AppConfig / endpoints', () {
    test('default base and API prefix match DEEIX deployment', () {
      expect(AppConfig.apiPrefix, '/api/v1');
      expect(AppConfig.apiBaseUrl, 'https://vps.cli-help.com');
      expect(ApiEndpoints.login, '/auth/login');
      expect(ApiEndpoints.refresh, '/auth/refresh');
      expect(ApiEndpoints.me, '/me');
      expect(ApiEndpoints.conversations, '/conversations');
      expect(
        ApiEndpoints.conversationMessageStream('abc'),
        '/conversations/abc/messages/stream',
      );
      expect(ApiEndpoints.models, '/models');
      expect(ApiEndpoints.files, '/files');
    });
  });

  group('ApiEnvelope', () {
    test('unwrapMap reads data from success envelope', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 200,
        data: {
          'errorMsg': '',
          'data': {
            'accessToken': 'tok_abc',
            'user': {'id': 1, 'username': 'alice'},
          },
        },
      );
      final data = ApiEnvelope.unwrapMap(response);
      expect(data['accessToken'], 'tok_abc');
    });

    test('unwrap throws with server errorMsg on HTTP 4xx', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 400,
        data: {
          'errorMsg': 'invalid request body: username must be at least 3',
          'errorCode': 'request.invalid_body',
          'data': null,
        },
      );
      expect(
        () => ApiEnvelope.unwrap(response),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('username must be at least 3'),
          ),
        ),
      );
    });

    test('fromDio maps envelope body', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 401,
          data: {
            'errorMsg': 'unauthorized',
            'errorCode': 'auth.unauthorized',
            'data': null,
          },
        ),
      );
      final api = ApiException.fromDio(e);
      expect(api.message, 'unauthorized');
      expect(api.errorCode, 'auth.unauthorized');
      expect(api.statusCode, 401);
    });

    test('unwrapResults reads data.results list', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/conversations'),
        statusCode: 200,
        data: {
          'errorMsg': '',
          'data': {
            'results': [
              {'publicID': 'c1', 'title': 'Hi'},
            ],
            'total': 1,
          },
        },
      );
      final results = ApiEnvelope.unwrapResults(response);
      expect(results, hasLength(1));
      expect((results.first as Map)['publicID'], 'c1');
    });
  });

  group('DTO mapping from Swagger-shaped JSON', () {
    test('User.fromApi maps AuthUserResponse / me.user', () {
      final user = User.fromApi({
        'user': {
          'id': 42,
          'publicID': 'u_pub',
          'username': 'bob',
          'displayName': 'Bob',
          'email': 'bob@example.com',
          'avatarURL': 'https://x/a.png',
          'role': 'user',
          'status': 'active',
        },
      });
      expect(user.id, 42);
      expect(user.publicID, 'u_pub');
      expect(user.displayLabel, 'Bob');
    });

    test('Conversation.fromApi uses publicID and isStarred', () {
      final c = Conversation.fromApi({
        'publicID': 'conv_xyz',
        'title': 'My chat',
        'model': 'gpt-test',
        'isStarred': true,
        'messageCount': 3,
        'updatedAt': '2026-07-01T12:00:00Z',
        'createdAt': '2026-07-01T11:00:00Z',
        'status': 'active',
      });
      expect(c.publicID, 'conv_xyz');
      expect(c.isStarred, isTrue);
      expect(c.displayTitle, 'My chat');
      expect(c.model, 'gpt-test');
      expect(c.updatedAt, isNotNull);
    });

    test('ChatMessage.fromApi prefers publicID', () {
      final m = ChatMessage.fromApi({
        'id': 9,
        'publicID': 'msg_abc',
        'role': 'assistant',
        'content': 'hello **world**',
        'contentType': 'markdown',
        'runID': 'run_1',
        'status': 'success',
        'platformModelName': 'demo-model',
        'createdAt': '2026-07-01T12:00:00Z',
      });
      expect(m.id, 'msg_abc');
      expect(m.serverMessageID, 9);
      expect(m.role, MessageRole.assistant);
      expect(m.content, 'hello **world**');
      expect(m.runID, 'run_1');
    });

    test('ChatMessage.fromApi maps attachments JSON string (web shape)', () {
      final raw = jsonEncode([
        {
          'file_id': 'fid1',
          'file_name': 'a.png',
          'mime_type': 'image/png',
          'kind': 'image',
        },
      ]);
      final m = ChatMessage.fromApi({
        'publicID': 'm1',
        'role': 'user',
        'content': 'pic',
        'attachments': raw,
      });
      expect(m.attachments, hasLength(1));
      expect(m.attachments.first.fileID, 'fid1');
      expect(m.attachments.first.isImage, isTrue);
      expect(MessageAttachment.parseAttachments(null), isEmpty);
    });
  });

  group('NdjsonObjectStream + mapStreamEvent', () {
    test('parses objects split across chunks', () async {
      final parser = NdjsonObjectStream();
      final bytes = Stream<List<int>>.fromIterable([
        utf8.encode('{"type":"delta","delta":"Hel'),
        utf8.encode('lo"}\n{"type":"completed","data":{"userMessage":'),
        utf8.encode(
          '{"publicID":"u1","role":"user","content":"hi"},'
          '"assistantMessage":{"publicID":"a1","role":"assistant","content":"Hello"}}}',
        ),
      ]);
      final events = await parser.parse(bytes).toList();
      expect(events, hasLength(2));
      expect(events[0]['type'], 'delta');

      final deltaChunk = mapStreamEvent(events[0]);
      expect(deltaChunk.delta, 'Hello');
      expect(deltaChunk.done, isFalse);

      final doneChunk = mapStreamEvent(events[1]);
      expect(doneChunk.done, isTrue);
      expect(doneChunk.finalUserMessage?.id, 'u1');
      expect(doneChunk.finalAssistantMessage?.content, 'Hello');
    });

    test('maps error event', () {
      final chunk = mapStreamEvent({
        'type': 'error',
        'message': 'quota exceeded',
        'seq': 3,
      });
      expect(chunk.done, isTrue);
      expect(chunk.error, 'quota exceeded');
      expect(chunk.seq, 3);
    });

    test('ignores process_update as non-terminal raw event', () {
      final chunk = mapStreamEvent({
        'type': 'process_update',
        'trace': {'status': 'running'},
      });
      expect(chunk.done, isFalse);
      expect(chunk.delta, isNull);
      expect(chunk.processStatus, 'running');
      expect(chunk.raw?['type'], 'process_update');
    });

    test('maps rag_search sources', () {
      final chunk = mapStreamEvent({
        'type': 'rag_search',
        'sources': [
          {'title': '手册.pdf'},
          {'fileName': 'notes.md'},
        ],
      });
      expect(chunk.done, isFalse);
      expect(chunk.ragSources, ['手册.pdf', 'notes.md']);
      expect(chunk.ragSummary, contains('2'));
    });

    test('maps file_proc label', () {
      final chunk = mapStreamEvent({
        'type': 'file_proc',
        'fileName': 'scan.pdf',
        'status': 'extracting',
      });
      expect(chunk.fileProcMessage, contains('scan.pdf'));
      expect(chunk.done, isFalse);
    });
  });

  group('message branch fields', () {
    test('fromApi reads parent/source/branchReason and processTrace rag', () {
      final msg = ChatMessage.fromApi({
        'publicID': 'a2',
        'role': 'assistant',
        'content': 'ans',
        'parentPublicID': 'u1',
        'sourcePublicID': 'a1',
        'branchReason': 'retry',
        'processTrace': {
          'status': 'completed',
          'promptTrace': {
            'blocks': [
              {
                'kind': 'rag',
                'title': '知识检索',
                'sourceRefs': [
                  {
                    'sourceType': 'file_chunk',
                    'title': '公司手册',
                    'sourceID': 's1',
                  },
                ],
              },
            ],
          },
          'upstreamThink': {'contentMarkdown': 'thinking…'},
        },
      });
      expect(msg.parentPublicID, 'u1');
      expect(msg.sourcePublicID, 'a1');
      expect(msg.branchReason, 'retry');
      expect(msg.processStatus, 'completed');
      expect(msg.thinking, 'thinking…');
      expect(msg.ragSources, contains('公司手册'));
      expect(msg.ragSummary, isNotNull);
    });

    test('filterBranchVisibleMessages keeps selected sibling', () {
      final messages = [
        ChatMessage.fromApi({'publicID': 'u1', 'role': 'user', 'content': 'q'}),
        ChatMessage.fromApi({
          'publicID': 'a1',
          'role': 'assistant',
          'content': 'v1',
          'parentPublicID': 'u1',
        }),
        ChatMessage.fromApi({
          'publicID': 'a2',
          'role': 'assistant',
          'content': 'v2',
          'parentPublicID': 'u1',
          'branchReason': 'retry',
        }),
      ];
      final latest = filterBranchVisibleMessages(messages);
      expect(latest.map((m) => m.id).toList(), ['u1', 'a2']);

      final first = filterBranchVisibleMessages(
        messages,
        selectedIndexByParent: const {'u1': 0},
      );
      expect(first.map((m) => m.id).toList(), ['u1', 'a1']);
    });
  });

  group('attachments preview helpers', () {
    test('detects pdf and text-like', () {
      final pdf = MessageAttachment(
        fileID: 'f1',
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
      );
      final txt = MessageAttachment(
        fileID: 'f2',
        fileName: 'n.md',
        mimeType: 'text/markdown',
      );
      expect(pdf.isPdf, isTrue);
      expect(pdf.canInAppPreview, isTrue);
      expect(txt.isTextLike, isTrue);
    });
  });
}
