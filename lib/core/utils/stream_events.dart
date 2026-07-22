import '../../shared/models/message.dart';
import 'ndjson_stream.dart';

/// Incremental event from POST .../messages/stream (application/x-ndjson).
class StreamChunk {
  const StreamChunk({
    this.delta,
    this.thinkDelta,
    this.done = false,
    this.error,
    this.raw,
    this.finalUserMessage,
    this.finalAssistantMessage,
    this.seq,
    this.processStatus,
    this.toolSummary,
    this.fileProcMessage,
    this.ragSummary,
    this.ragSources,
  });

  final String? delta;

  /// Reasoning / upstream think text delta.
  final String? thinkDelta;
  final bool done;
  final String? error;
  final Map<String, dynamic>? raw;
  final ChatMessage? finalUserMessage;
  final ChatMessage? finalAssistantMessage;
  final int? seq;
  final String? processStatus;
  final String? toolSummary;
  final String? fileProcMessage;
  final String? ragSummary;
  final List<String>? ragSources;
}

/// Maps one DEEIX NDJSON stream event object to a [StreamChunk].
StreamChunk mapStreamEvent(Map<String, dynamic> event) {
  final type = '${event['type'] ?? ''}';
  final seq = event['seq'] is int ? event['seq'] as int : null;

  if (type == StreamEventType.delta) {
    final delta = event['delta'];
    return StreamChunk(
      delta: delta is String ? delta : delta?.toString(),
      seq: seq,
      raw: event,
    );
  }

  if (type == StreamEventType.upstreamThinkDelta) {
    final delta = event['delta'] ?? event['content'] ?? event['text'];
    return StreamChunk(
      thinkDelta: delta is String ? delta : delta?.toString(),
      seq: seq,
      raw: event,
    );
  }

  if (type == StreamEventType.processUpdate) {
    final status = _processStatus(event);
    final tools = _toolSummary(event);
    return StreamChunk(
      processStatus: status,
      toolSummary: tools,
      seq: seq,
      raw: event,
    );
  }

  if (type == StreamEventType.fileProc) {
    return StreamChunk(
      fileProcMessage: _fileProcLabel(event),
      processStatus: _processStatus(event) ?? 'file_processing',
      seq: seq,
      raw: event,
    );
  }

  if (type == StreamEventType.ragSearch) {
    final sources = _ragSources(event);
    final summary = sources.isNotEmpty
        ? '检索到 ${sources.length} 条知识源'
        : _ragLabel(event);
    return StreamChunk(
      ragSummary: summary,
      ragSources: sources.isEmpty ? null : sources,
      processStatus: 'rag_search',
      fileProcMessage: summary,
      seq: seq,
      raw: event,
    );
  }

  if (type == StreamEventType.completed) {
    ChatMessage? userMsg;
    ChatMessage? assistantMsg;
    final data = event['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['userMessage'] is Map) {
        userMsg = ChatMessage.fromApi(
          Map<String, dynamic>.from(map['userMessage'] as Map),
        );
      }
      if (map['assistantMessage'] is Map) {
        assistantMsg = ChatMessage.fromApi(
          Map<String, dynamic>.from(map['assistantMessage'] as Map),
        );
      }
    }
    return StreamChunk(
      done: true,
      seq: seq,
      raw: event,
      finalUserMessage: userMsg,
      finalAssistantMessage: assistantMsg,
    );
  }

  if (type == StreamEventType.error) {
    final errMsg =
        event['message'] as String? ??
        (event['errorMsg'] is String && (event['errorMsg'] as String).isNotEmpty
            ? event['errorMsg'] as String
            : null) ??
        'stream failed';
    return StreamChunk(done: true, error: errMsg, seq: seq, raw: event);
  }

  return StreamChunk(raw: event, seq: seq);
}

String? _processStatus(Map<String, dynamic> event) {
  final trace = event['trace'];
  if (trace is Map && trace['status'] != null) {
    return '${trace['status']}';
  }
  if (event['status'] != null) return '${event['status']}';
  return 'processing';
}

String? _toolSummary(Map<String, dynamic> event) {
  final trace = event['trace'];
  if (trace is! Map) return null;
  final tools = trace['tools'];
  if (tools is List && tools.isNotEmpty) {
    return tools
        .map((t) {
          if (t is Map) {
            return '${t['name'] ?? t['toolName'] ?? t['title'] ?? 'tool'}: '
                '${t['status'] ?? t['state'] ?? ''}';
          }
          return '$t';
        })
        .join('\n');
  }
  final events = trace['events'];
  if (events is List && events.isNotEmpty) {
    final last = events.last;
    if (last is Map) {
      return '${last['title'] ?? last['eventType'] ?? 'event'}: '
          '${last['status'] ?? last['summary'] ?? ''}';
    }
  }
  return null;
}

String _fileProcLabel(Map<String, dynamic> event) {
  final message = '${event['message'] ?? ''}'.trim();
  if (message.isNotEmpty) return message;
  final status = '${event['status'] ?? event['phase'] ?? ''}'.trim();
  final fileName =
      '${event['fileName'] ?? event['file_name'] ?? event['name'] ?? ''}'
          .trim();
  final stage = '${event['stage'] ?? event['extractStatus'] ?? ''}'.trim();
  final parts = <String>[
    if (fileName.isNotEmpty) fileName,
    if (stage.isNotEmpty) stage,
    if (status.isNotEmpty) status,
  ];
  if (parts.isNotEmpty) return parts.join(' · ');
  return '文件处理中…';
}

String _ragLabel(Map<String, dynamic> event) {
  final message = '${event['message'] ?? event['summary'] ?? ''}'.trim();
  if (message.isNotEmpty) return message;
  final status = '${event['status'] ?? ''}'.trim();
  if (status.isNotEmpty) return '知识检索 · $status';
  return '知识检索中…';
}

List<String> _ragSources(Map<String, dynamic> event) {
  final out = <String>[];
  void add(String s) {
    final t = s.trim();
    if (t.isNotEmpty && !out.contains(t)) out.add(t);
  }

  final candidates = [
    event['sources'],
    event['results'],
    event['hits'],
    event['documents'],
    event['chunks'],
  ];
  for (final c in candidates) {
    if (c is! List) continue;
    for (final item in c) {
      if (item is String) {
        add(item);
      } else if (item is Map) {
        add(
          '${item['title'] ?? item['fileName'] ?? item['file_name'] ?? item['source'] ?? item['name'] ?? item['id'] ?? ''}',
        );
      }
    }
  }
  final single = '${event['title'] ?? event['fileName'] ?? ''}'.trim();
  if (single.isNotEmpty) add(single);
  return out;
}

/// Feedback body for PUT /messages/{id}/feedback
Map<String, dynamic> messageFeedbackBody(String? feedback) {
  // empty / null clears feedback per API description
  if (feedback == null || feedback.isEmpty) {
    return {'feedback': null};
  }
  return {'feedback': feedback}; // "up" | "down"
}

/// Groups assistant messages that share the same [ChatMessage.parentPublicID].
/// Returns map of parentPublicID → sibling messages (stable order).
Map<String, List<ChatMessage>> groupAssistantBranches(
  List<ChatMessage> messages,
) {
  final map = <String, List<ChatMessage>>{};
  for (final m in messages) {
    if (m.role != MessageRole.assistant) continue;
    final parent = m.parentPublicID;
    if (parent == null || parent.isEmpty) continue;
    map.putIfAbsent(parent, () => []).add(m);
  }
  return map;
}

/// Filters [messages] so only the selected sibling of each branch group remains.
/// [selectedIndexByParent] maps parentPublicID → sibling index (default: last).
List<ChatMessage> filterBranchVisibleMessages(
  List<ChatMessage> messages, {
  Map<String, int> selectedIndexByParent = const {},
}) {
  final groups = groupAssistantBranches(messages);
  if (groups.isEmpty) return messages;

  final hidden = <String>{};
  for (final entry in groups.entries) {
    final siblings = entry.value;
    if (siblings.length <= 1) continue;
    final rawIdx = selectedIndexByParent[entry.key] ?? (siblings.length - 1);
    final idx = rawIdx.clamp(0, siblings.length - 1);
    for (var i = 0; i < siblings.length; i++) {
      if (i != idx) hidden.add(siblings[i].id);
    }
  }
  if (hidden.isEmpty) return messages;
  return messages.where((m) => !hidden.contains(m.id)).toList();
}
