import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_attachment.dart';

part 'message.freezed.dart';
part 'message.g.dart';

enum MessageRole {
  user,
  assistant,
  system,
  tool,
  unknown;

  static MessageRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'user':
      case 'human':
        return MessageRole.user;
      case 'assistant':
      case 'ai':
      case 'bot':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      case 'tool':
      case 'function':
        return MessageRole.tool;
      default:
        return MessageRole.unknown;
    }
  }
}

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    int? serverMessageID,
    required MessageRole role,
    @Default('') String content,
    @Default('text') String contentType,
    String? runID,
    String? status,
    String? platformModelName,
    DateTime? createdAt,
    @Default(false) bool isStreaming,
    String? error,
    @Default('') String thinking,
    String? processStatus,
    String? toolSummary,
    String? myFeedback,

    /// Branch tree: parent user/assistant publicID.
    String? parentPublicID,

    /// Branch source (e.g. regenerated-from) publicID.
    String? sourcePublicID,

    /// `default` | `retry` | `edit`
    String? branchReason,

    /// Compact RAG / retrieval summary for the process panel.
    String? ragSummary,

    /// File OCR / embedding progress note from stream events.
    String? fileProcMessage,
    @Default(<String>[])
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<String> ragSources,
    @Default(<MessageAttachment>[])
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<MessageAttachment> attachments,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  factory ChatMessage.fromApi(Map<String, dynamic> json) {
    DateTime? parseTime(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    final publicID = '${json['publicID'] ?? ''}'.trim();
    final numericId = json['id'];
    final id = publicID.isNotEmpty
        ? publicID
        : '${numericId ?? DateTime.now().microsecondsSinceEpoch}';

    final attachments = MessageAttachment.parseAttachments(json['attachments']);
    final trace = _parseProcessTrace(json['processTrace']);

    return ChatMessage(
      id: id,
      serverMessageID: numericId is int
          ? numericId
          : int.tryParse('$numericId'),
      role: MessageRole.fromString(json['role'] as String?),
      content: '${json['content'] ?? ''}',
      contentType: '${json['contentType'] ?? 'text'}',
      runID: json['runID'] as String?,
      status: json['status'] as String?,
      platformModelName: json['platformModelName'] as String?,
      createdAt: parseTime(json['createdAt'] ?? json['created_at']),
      error: (json['errorMessage'] as String?)?.isNotEmpty == true
          ? json['errorMessage'] as String
          : null,
      myFeedback: json['myFeedback'] as String?,
      parentPublicID: _optionalId(json['parentPublicID']),
      sourcePublicID: _optionalId(json['sourcePublicID']),
      branchReason: json['branchReason'] as String?,
      processStatus: trace.status,
      toolSummary: trace.toolSummary,
      thinking: trace.thinking,
      ragSummary: trace.ragSummary,
      ragSources: trace.ragSources,
      attachments: attachments,
    );
  }

  factory ChatMessage.localUser(
    String content, {
    List<MessageAttachment> attachments = const [],
    String contentType = 'text',
    String? parentPublicID,
    String? sourcePublicID,
    String? branchReason,
  }) => ChatMessage(
    id: 'local-user-${DateTime.now().microsecondsSinceEpoch}',
    role: MessageRole.user,
    content: content,
    contentType: contentType,
    createdAt: DateTime.now(),
    attachments: attachments,
    parentPublicID: parentPublicID,
    sourcePublicID: sourcePublicID,
    branchReason: branchReason,
  );

  factory ChatMessage.streamingAssistant({
    String? parentPublicID,
    String? sourcePublicID,
    String? branchReason,
  }) => ChatMessage(
    id: 'local-assistant-${DateTime.now().microsecondsSinceEpoch}',
    role: MessageRole.assistant,
    content: '',
    contentType: 'text',
    createdAt: DateTime.now(),
    isStreaming: true,
    parentPublicID: parentPublicID,
    sourcePublicID: sourcePublicID,
    branchReason: branchReason,
  );
}

String? _optionalId(dynamic v) {
  final s = '${v ?? ''}'.trim();
  return s.isEmpty ? null : s;
}

class _TraceParse {
  const _TraceParse({
    this.status,
    this.toolSummary,
    this.thinking = '',
    this.ragSummary,
    this.ragSources = const [],
  });
  final String? status;
  final String? toolSummary;
  final String thinking;
  final String? ragSummary;
  final List<String> ragSources;
}

_TraceParse _parseProcessTrace(dynamic raw) {
  if (raw is! Map) return const _TraceParse();
  final map = Map<String, dynamic>.from(raw);
  final status = map['status'] != null ? '${map['status']}' : null;

  String? toolSummary;
  final tools = map['tools'];
  if (tools is Map) {
    final title = '${tools['title'] ?? ''}'.trim();
    final summary = '${tools['summary'] ?? ''}'.trim();
    final stage = '${tools['stage'] ?? ''}'.trim();
    final tStatus = '${tools['status'] ?? ''}'.trim();
    final parts = [
      if (title.isNotEmpty) title,
      if (stage.isNotEmpty) stage,
      if (tStatus.isNotEmpty) tStatus,
      if (summary.isNotEmpty) summary,
    ];
    if (parts.isNotEmpty) toolSummary = parts.join(' · ');
  }

  var thinking = '';
  final think = map['upstreamThink'];
  if (think is Map) {
    final md = '${think['contentMarkdown'] ?? ''}'.trim();
    final summary = '${think['summary'] ?? ''}'.trim();
    thinking = md.isNotEmpty ? md : summary;
  }

  final sources = <String>[];
  final promptTrace = map['promptTrace'];
  if (promptTrace is Map) {
    final blocks = promptTrace['blocks'];
    if (blocks is List) {
      for (final b in blocks) {
        if (b is! Map) continue;
        final kind = '${b['kind'] ?? ''}'.toLowerCase();
        final title = '${b['title'] ?? ''}'.trim();
        final refs = b['sourceRefs'];
        if (refs is List) {
          for (final r in refs) {
            if (r is! Map) continue;
            final st = '${r['sourceType'] ?? ''}'.toLowerCase();
            final rt = '${r['title'] ?? r['sourceID'] ?? ''}'.trim();
            if (rt.isEmpty) continue;
            if (st.contains('rag') ||
                st.contains('file') ||
                st.contains('chunk') ||
                st.contains('doc') ||
                kind.contains('rag') ||
                kind.contains('retriev')) {
              sources.add(rt);
            }
          }
        }
        if (sources.isEmpty &&
            title.isNotEmpty &&
            (kind.contains('rag') ||
                kind.contains('retriev') ||
                kind.contains('file'))) {
          sources.add(title);
        }
      }
    }
  }

  // Fall back: scan events for rag/file titles.
  final events = map['events'];
  if (events is List) {
    for (final e in events) {
      if (e is! Map) continue;
      final et = '${e['eventType'] ?? e['stage'] ?? ''}'.toLowerCase();
      final title = '${e['title'] ?? ''}'.trim();
      final summary = '${e['summary'] ?? ''}'.trim();
      if (et.contains('rag') || et.contains('retriev') || et.contains('file')) {
        final label = title.isNotEmpty ? title : summary;
        if (label.isNotEmpty) sources.add(label);
      }
    }
  }

  final uniqueSources = <String>[];
  for (final s in sources) {
    if (!uniqueSources.contains(s)) uniqueSources.add(s);
  }

  String? ragSummary;
  if (uniqueSources.isNotEmpty) {
    ragSummary = '检索到 ${uniqueSources.length} 条知识源';
  }

  return _TraceParse(
    status: status,
    toolSummary: toolSummary,
    thinking: thinking,
    ragSummary: ragSummary,
    ragSources: uniqueSources,
  );
}
