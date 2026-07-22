import 'dart:async';
import 'dart:convert';

/// Parses Server-Sent Events / chunked JSON streams from DEEIX-Chat.
///
/// Real wire format should be confirmed via browser Network tab.
/// This parser is defensive:
/// - Standard SSE (`data: ...` lines)
/// - Newline-delimited JSON objects
/// - Optional `event:` field (ignored for content accumulation)
class SseParser {
  SseParser();

  final StringBuffer _lineBuffer = StringBuffer();

  /// Feed raw UTF-8 chunks; yields complete data payloads (string per event).
  Stream<String> parse(Stream<List<int>> byteStream) async* {
    await for (final bytes in byteStream) {
      _lineBuffer.write(utf8.decode(bytes, allowMalformed: true));
      final text = _lineBuffer.toString();
      final parts = text.split('\n');

      // Keep incomplete trailing line.
      _lineBuffer.clear();
      if (!text.endsWith('\n')) {
        _lineBuffer.write(parts.removeLast());
      } else if (parts.isNotEmpty && parts.last.isEmpty) {
        parts.removeLast();
      }

      final eventData = <String>[];
      for (final rawLine in parts) {
        final line = rawLine.endsWith('\r')
            ? rawLine.substring(0, rawLine.length - 1)
            : rawLine;

        if (line.isEmpty) {
          if (eventData.isNotEmpty) {
            yield eventData.join('\n');
            eventData.clear();
          }
          continue;
        }

        if (line.startsWith(':')) {
          // SSE comment / keepalive
          continue;
        }

        if (line.startsWith('data:')) {
          final payload = line.substring(5).trimLeft();
          if (payload == '[DONE]') {
            if (eventData.isNotEmpty) {
              yield eventData.join('\n');
              eventData.clear();
            }
            return;
          }
          eventData.add(payload);
          continue;
        }

        // NDJSON fallback: whole line is JSON.
        if (line.startsWith('{') || line.startsWith('[')) {
          yield line;
        }
      }

      // Flush data: lines that arrived without trailing blank line (chunked).
      if (eventData.isNotEmpty) {
        yield eventData.join('\n');
        eventData.clear();
      }
    }

    // Flush remainder.
    final rest = _lineBuffer.toString().trim();
    if (rest.isNotEmpty) {
      if (rest.startsWith('data:')) {
        yield rest.substring(5).trimLeft();
      } else {
        yield rest;
      }
    }
  }

  /// Decode a data payload into a Map when possible.
  static Map<String, dynamic>? tryJsonMap(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  /// Common streaming content extractors (adapt after packet capture).
  static String? extractDeltaText(Map<String, dynamic> json) {
    // OpenAI-style
    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final delta = first['delta'];
        if (delta is Map && delta['content'] is String) {
          return delta['content'] as String;
        }
        if (first['text'] is String) return first['text'] as String;
      }
    }

    for (final key in ['content', 'delta', 'text', 'message', 'chunk']) {
      final v = json[key];
      if (v is String && v.isNotEmpty) return v;
      if (v is Map) {
        final nested = v['content'] ?? v['text'];
        if (nested is String) return nested;
      }
    }

    final data = json['data'];
    if (data is Map) {
      return extractDeltaText(Map<String, dynamic>.from(data));
    }
    return null;
  }
}
