import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deeix_client/core/network/api_response.dart';
import 'package:deeix_client/features/auth/data/two_factor_repository.dart';
import 'package:deeix_client/features/billing/data/billing_repository.dart';
import 'package:deeix_client/features/chat/data/chat_repository.dart';
import 'package:deeix_client/features/conversation/data/conversation_repository.dart';
import 'package:deeix_client/features/knowledge/data/knowledge_repository.dart';
import 'package:deeix_client/features/model_provider/data/model_provider_repository.dart';
import 'package:deeix_client/shared/models/conversation.dart';

/// Records requests and answers with canned JSON (or NDJSON) bodies.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final ({int status, String body}) Function(RequestOptions o) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final r = handler(options);
    return ResponseBody.fromString(
      r.body,
      r.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(Dio, FakeAdapter) _dio(
  ({int status, String body}) Function(RequestOptions) h,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://x/api/v1'));
  final adapter = FakeAdapter(h);
  dio.httpClientAdapter = adapter;
  return (dio, adapter);
}

String _ok(Object data) => jsonEncode({'errorMsg': '', 'data': data});

void main() {
  group('KnowledgeRepository', () {
    test('lists visible knowledge bases', () async {
      final (dio, a) = _dio(
        (_) => (
          status: 200,
          body: _ok({
            'total': 1,
            'results': [
              {
                'publicID': 'kb1',
                'name': '产品文档',
                'scope': 'builtin',
                'fileCount': 3,
                'readyFileCount': 2,
              },
            ],
          }),
        ),
      );
      final list = await KnowledgeRepository(dio).listVisible();
      expect(a.requests.single.path, '/knowledge-bases');
      expect(list.single.name, '产品文档');
      expect(list.single.isMine, isFalse);
      expect(list.single.readyFileCount, 2);
    });

    test('create / addFiles / removeFile hit the mine endpoints', () async {
      final (dio, a) = _dio(
        (o) => (
          status: 200,
          body: _ok({
            'knowledgeBase': {'publicID': 'kb9', 'name': 'n', 'scope': 'user'},
          }),
        ),
      );
      final repo = KnowledgeRepository(dio);
      final kb = await repo.create(name: ' 我的库 ', description: 'd');
      await repo.addFiles('kb9', ['f1', 'f2']);
      await repo.removeFile('kb9', 'f1');
      expect(kb.publicID, 'kb9');
      expect(a.requests[0].method, 'POST');
      expect(a.requests[0].path, '/knowledge-bases/mine');
      expect(a.requests[0].data, {'name': '我的库', 'description': 'd'});
      expect(a.requests[1].path, '/knowledge-bases/mine/kb9/files');
      expect(a.requests[1].data, {
        'fileIDs': ['f1', 'f2'],
      });
      expect(a.requests[2].method, 'DELETE');
      expect(a.requests[2].path, '/knowledge-bases/mine/kb9/files/f1');
    });
  });

  group('ModelProviderRepository', () {
    test('list + probe parse models', () async {
      final (dio, a) = _dio((o) {
        if (o.path.endsWith('/probe')) {
          return (
            status: 200,
            body: _ok({
              'models': [
                {'name': 'gpt-x', 'suggestedProtocols': []},
              ],
            }),
          );
        }
        return (
          status: 200,
          body: _ok({
            'providers': [
              {
                'id': 'p1',
                'name': 'My OpenAI',
                'protocol': 'openai',
                'keyHint': 'sk-…abcd',
                'status': 'active',
                'models': [
                  {
                    'name': 'gpt-x',
                    'protocols': ['openai'],
                  },
                ],
              },
            ],
          }),
        );
      });
      final repo = ModelProviderRepository(dio);
      final list = await repo.list();
      expect(list.single.models, ['gpt-x']);
      expect(list.single.enabled, isTrue);
      final probed = await repo.probe(
        protocol: 'openai',
        baseURL: ' https://api.example.com/v1 ',
        apiKey: ' k ',
      );
      expect(probed, ['gpt-x']);
      expect(a.requests[1].data, {
        'protocol': 'openai',
        'baseURL': 'https://api.example.com/v1',
        'apiKey': 'k',
      });
    });

    test('update omits empty api key', () async {
      final (dio, a) = _dio(
        (_) => (
          status: 200,
          body: _ok({
            'provider': {'id': 'p1', 'name': 'n', 'status': 'disabled'},
          }),
        ),
      );
      final p = await ModelProviderRepository(
        dio,
      ).update('p1', apiKey: '  ', enabled: false);
      expect(p.enabled, isFalse);
      expect(a.requests.single.method, 'PATCH');
      expect(a.requests.single.data, {'enabled': false});
    });
  });

  group('TwoFactorRepository', () {
    test('status + confirm return recovery codes', () async {
      final (dio, a) = _dio((o) {
        if (o.path == '/me/2fa') {
          return (
            status: 200,
            body: _ok({'available': true, 'totpEnabled': false}),
          );
        }
        return (
          status: 200,
          body: _ok({
            'recoveryCodes': ['a', 'b'],
            'status': {'totpEnabled': true},
          }),
        );
      });
      final repo = TwoFactorRepository(dio);
      expect((await repo.status()).available, isTrue);
      expect(await repo.confirmSetup(' 123456 '), ['a', 'b']);
      expect(a.requests[1].path, '/me/2fa/setup/confirm');
      expect(a.requests[1].data, {'code': '123456'});
    });
  });

  group('ConversationRepository 0.4.4 additions', () {
    test('search, labels, delete message, fork', () async {
      final (dio, a) = _dio((o) {
        if (o.path == '/conversations/search') {
          return (
            status: 200,
            body: _ok({
              'hasMore': true,
              'results': [
                {'publicID': 'c1', 'title': 't', 'labelsJSON': '["工作"]'},
              ],
            }),
          );
        }
        if (o.method == 'DELETE') {
          return (status: 200, body: _ok({'deleted': true}));
        }
        return (
          status: 200,
          body: _ok({'publicID': 'c2', 'labelsJSON': '["a","b"]'}),
        );
      });
      final repo = ConversationRepository(dio);
      final s = await repo.search(' 关键字 ');
      expect(s.hasMore, isTrue);
      expect(s.results.single.labels, ['工作']);
      expect(a.requests[0].queryParameters['q'], '关键字');

      final c = await repo.setLabels('c1', ['a', 'b']);
      expect(c.labels, ['a', 'b']);
      expect(a.requests[1].path, '/conversations/c1/labels');

      await repo.deleteMessage('c1', 'm1');
      expect(a.requests[2].path, '/conversations/c1/messages/m1');

      final forked = await repo.forkFromMessage('c1', 'm1');
      expect(forked.publicID, 'c2');
      expect(a.requests[3].path, '/conversations/c1/messages/m1/fork');
    });

    test('parseLabels tolerates bad input', () {
      expect(Conversation.parseLabels(null), isEmpty);
      expect(Conversation.parseLabels('not json'), isEmpty);
      expect(Conversation.parseLabels(['x', ' ']), ['x']);
    });
  });

  group('BillingRepository.activity', () {
    test('parses daily activity list', () async {
      final (dio, a) = _dio(
        (_) => (
          status: 200,
          body: _ok([
            {'date': '2026-10-12', 'requestCount': 5, 'tokenUsage': 1200},
          ]),
        ),
      );
      final list = await BillingRepository(dio).activity(days: 7);
      expect(list.single.tokenUsage, 1200);
      expect(a.requests.single.queryParameters['days'], 7);
    });
  });

  group('ChatRepository streams', () {
    test('temporary chat posts full history and parses NDJSON', () async {
      final (dio, a) = _dio(
        (_) => (
          status: 200,
          body:
              '{"type":"delta","delta":"你"}\n{"type":"delta","delta":"好"}\n'
              '{"type":"completed","data":{}}\n',
        ),
      );
      final chunks = await ChatRepository(dio)
          .streamTemporaryChat(
            sessionId: 's',
            clientRunId: 'r',
            model: 'm',
            messages: [(role: 'user', content: 'hi')],
          )
          .toList();
      expect(a.requests.single.path, '/temporary-chat/messages/stream');
      final body = a.requests.single.data as Map;
      expect(body['messages'], [
        {'role': 'user', 'content': 'hi'},
      ]);
      expect(chunks.map((c) => c.delta).whereType<String>().join(), '你好');
      expect(chunks.last.done, isTrue);
    });

    test('media generation picks endpoint by kind / inputs', () async {
      final (dio, a) = _dio(
        (_) => (status: 200, body: '{"type":"completed","data":{}}\n'),
      );
      final repo = ChatRepository(dio);
      await repo
          .streamMediaGeneration(
            conversationPublicId: 'c1',
            kind: MediaKind.image,
            prompt: 'cat',
          )
          .toList();
      await repo
          .streamMediaGeneration(
            conversationPublicId: 'c1',
            kind: MediaKind.image,
            prompt: 'cat',
            fileIds: ['f'],
          )
          .toList();
      await repo
          .streamMediaGeneration(
            conversationPublicId: 'c1',
            kind: MediaKind.video,
            prompt: 'cat',
          )
          .toList();
      expect(a.requests.map((r) => r.path).toList(), [
        '/conversations/c1/media/images/generations/stream',
        '/conversations/c1/media/images/edits/stream',
        '/conversations/c1/media/videos/generations/stream',
      ]);
    });

    test('stream error surfaces server errorMsg', () async {
      final (dio, _) = _dio(
        (_) => (status: 403, body: '{"errorMsg":"模型不可用","data":null}'),
      );
      await expectLater(
        ChatRepository(
          dio,
        ).streamMessage(conversationPublicId: 'c', content: 'x').toList(),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', '模型不可用'),
        ),
      );
    });

    test('streamMessage sends knowledgeBaseIDs', () async {
      final (dio, a) = _dio(
        (_) => (status: 200, body: '{"type":"completed","data":{}}\n'),
      );
      await ChatRepository(dio)
          .streamMessage(
            conversationPublicId: 'c',
            content: 'x',
            knowledgeBaseIds: ['kb1'],
          )
          .toList();
      expect((a.requests.single.data as Map)['knowledgeBaseIDs'], ['kb1']);
    });
  });
}
