import 'dart:convert';

import 'package:dio/dio.dart';

/// DEEIX Chat API envelope: `{ "data": T, "errorMsg": "" }`.
///
/// Errors often also include `errorCode`, `details`, `requestId`.
class ApiEnvelope {
  ApiEnvelope._();

  static Map<String, dynamic> asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static dynamic dataOf(dynamic raw) => asMap(raw)['data'];

  static String? errorMsgOf(dynamic raw) {
    final msg = asMap(raw)['errorMsg'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    return null;
  }

  static String? errorCodeOf(dynamic raw) {
    final code = asMap(raw)['errorCode'];
    if (code is String && code.isNotEmpty) return code;
    return null;
  }

  /// Throws [ApiException] when HTTP status or envelope indicates failure.
  static dynamic unwrap(Response response) {
    final status = response.statusCode ?? 0;
    final body = response.data;
    final err = errorMsgOf(body);

    if (status >= 400) {
      throw ApiException(
        message: err ?? '请求失败 ($status)',
        statusCode: status,
        errorCode: errorCodeOf(body),
        details: asMap(body)['details'],
        requestId: asMap(body)['requestId'] as String?,
      );
    }

    // Some endpoints may return 200 with errorMsg set.
    if (err != null) {
      throw ApiException(
        message: err,
        statusCode: status,
        errorCode: errorCodeOf(body),
        details: asMap(body)['details'],
        requestId: asMap(body)['requestId'] as String?,
      );
    }

    return dataOf(body);
  }

  static Map<String, dynamic> unwrapMap(Response response) {
    final data = unwrap(response);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  static List<dynamic> unwrapResults(Response response) {
    final data = unwrap(response);
    if (data is List) return data;
    if (data is Map) {
      final results = data['results'];
      if (results is List) return results;
    }
    return const [];
  }
}

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
    this.requestId,
  });

  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;
  final String? requestId;

  /// Map Dio errors (with DEEIX envelope body) into [ApiException].
  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    if (res != null) {
      final body = res.data;
      final msg = ApiEnvelope.errorMsgOf(body);
      if (msg != null) {
        return ApiException(
          message: msg,
          statusCode: res.statusCode,
          errorCode: ApiEnvelope.errorCodeOf(body),
          details: ApiEnvelope.asMap(body)['details'],
          requestId: ApiEnvelope.asMap(body)['requestId'] as String?,
        );
      }
      return ApiException(
        message: e.message ?? '请求失败 (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return ApiException(message: e.message ?? e.toString());
  }

  @override
  String toString() => message;
}

/// Builds an [ApiException] from a failed `ResponseType.stream` request.
///
/// With a stream response type Dio leaves the error body as an unread
/// [ResponseBody], so [ApiException.fromDio] cannot see the server's
/// `errorMsg`. This drains (a bounded amount of) the body and decodes it.
Future<ApiException> apiExceptionFromStreamError(DioException e) async {
  final res = e.response;
  final body = res?.data;
  if (res == null || body is! ResponseBody) return ApiException.fromDio(e);
  final status = res.statusCode;
  try {
    final bytes = <int>[];
    await for (final chunk in body.stream) {
      bytes.addAll(chunk);
      if (bytes.length > 64 * 1024) break;
    }
    final text = utf8.decode(bytes, allowMalformed: true);
    final decoded = jsonDecode(text);
    final msg = ApiEnvelope.errorMsgOf(decoded);
    return ApiException(
      message: msg ?? '请求失败 ($status)',
      statusCode: status,
      errorCode: ApiEnvelope.errorCodeOf(decoded),
      details: ApiEnvelope.asMap(decoded)['details'],
      requestId: ApiEnvelope.asMap(decoded)['requestId'] as String?,
    );
  } catch (_) {
    return ApiException(message: '请求失败 ($status)', statusCode: status);
  }
}
