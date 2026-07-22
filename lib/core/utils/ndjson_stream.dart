import 'dart:async';
import 'dart:convert';

/// Brace-balanced JSON object extractor (same approach as DEEIX web client).
///
/// Stream body is `application/x-ndjson` but objects may span chunk boundaries;
/// this walks the buffer and yields complete top-level `{...}` documents.
class NdjsonObjectStream {
  NdjsonObjectStream();

  String _buffer = '';

  /// Feed raw UTF-8 byte chunks; yields decoded JSON maps.
  Stream<Map<String, dynamic>> parse(Stream<List<int>> byteStream) async* {
    await for (final bytes in byteStream) {
      _buffer += utf8.decode(bytes, allowMalformed: true);
      final extracted = _extractObjects(_buffer);
      _buffer = extracted.remainder;
      for (final doc in extracted.documents) {
        try {
          final decoded = jsonDecode(doc);
          if (decoded is Map<String, dynamic>) {
            yield decoded;
          } else if (decoded is Map) {
            yield Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // Skip malformed fragment; next chunk may complete it.
        }
      }
    }

    final tail = _buffer.trim();
    if (tail.isNotEmpty) {
      try {
        final decoded = jsonDecode(tail);
        if (decoded is Map<String, dynamic>) {
          yield decoded;
        } else if (decoded is Map) {
          yield Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
  }

  static ({List<String> documents, String remainder}) _extractObjects(
    String input,
  ) {
    final documents = <String>[];
    var objectStart = -1;
    var depth = 0;
    var inString = false;
    var escaped = false;
    var scanFrom = 0;

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];

      if (objectStart < 0) {
        if (ch == '{') {
          objectStart = i;
          depth = 1;
          scanFrom = i;
        } else if (ch.trim().isEmpty) {
          scanFrom = i + 1;
        } else {
          // Unexpected non-JSON noise — advance past it.
          scanFrom = i + 1;
        }
        continue;
      }

      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }

      if (ch == '"') {
        inString = true;
        continue;
      }
      if (ch == '{') {
        depth++;
        continue;
      }
      if (ch == '}') {
        depth--;
        if (depth == 0) {
          documents.add(input.substring(objectStart, i + 1));
          objectStart = -1;
          scanFrom = i + 1;
        }
      }
    }

    if (objectStart >= 0) {
      return (documents: documents, remainder: input.substring(objectStart));
    }
    return (documents: documents, remainder: input.substring(scanFrom));
  }
}

/// DEEIX Chat stream event types (from web client).
abstract class StreamEventType {
  static const delta = 'delta';
  static const completed = 'completed';
  static const error = 'error';
  static const usage = 'usage';
  static const processUpdate = 'process_update';
  static const upstreamThinkDelta = 'upstream_think_delta';
  static const fileProc = 'file_proc';
  static const ragSearch = 'rag_search';
  static const compactDone = 'compact_done';
  static const mediaStatus = 'media_status';
  static const mediaImageDelta = 'media_image_delta';
}
