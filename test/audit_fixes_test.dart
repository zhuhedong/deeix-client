import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deeix_client/core/network/api_response.dart';
import 'package:deeix_client/core/utils/ndjson_stream.dart';
import 'package:deeix_client/core/utils/stream_events.dart';

void main() {
  test('NDJSON keeps multi-byte UTF-8 split across chunks intact', () async {
    final bytes = utf8.encode('{"type":"delta","delta":"你好世界"}\n');
    // Split inside the 3-byte encoding of "你".
    final split = bytes.indexOf(0xE4) + 1;
    final chunks = Stream<List<int>>.fromIterable([
      bytes.sublist(0, split),
      bytes.sublist(split),
    ]);
    final events = await NdjsonObjectStream().parse(chunks).toList();
    expect(events.single['delta'], '你好世界');
  });

  test('moderation_blocked is terminal with an error', () {
    final chunk = mapStreamEvent({
      'type': 'moderation_blocked',
      'direction': 'input',
    });
    expect(chunk.done, isTrue);
    expect(chunk.error, contains('拦截'));
  });

  test('media_status shows progress, not terminal', () {
    final chunk = mapStreamEvent({
      'type': 'media_status',
      'status': 'generating',
      'message': '正在生成图片',
    });
    expect(chunk.done, isFalse);
    expect(chunk.processStatus, 'generating');
    expect(chunk.fileProcMessage, '正在生成图片');
  });

  test('apiExceptionFromStreamError reads errorMsg from stream body', () async {
    final body = ResponseBody(
      Stream.value(
        Uint8List.fromList(
          utf8.encode(
            '{"errorMsg":"余额不足","errorCode":"billing.insufficient","data":null}',
          ),
        ),
      ),
      402,
    );
    final req = RequestOptions(path: '/x');
    final e = DioException.badResponse(
      statusCode: 402,
      requestOptions: req,
      response: Response(requestOptions: req, statusCode: 402, data: body),
    );
    final ex = await apiExceptionFromStreamError(e);
    expect(ex.message, '余额不足');
    expect(ex.statusCode, 402);
    expect(ex.errorCode, 'billing.insufficient');
  });
}
