// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  serverMessageID: (json['serverMessageID'] as num?)?.toInt(),
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  content: json['content'] as String? ?? '',
  contentType: json['contentType'] as String? ?? 'text',
  runID: json['runID'] as String?,
  status: json['status'] as String?,
  platformModelName: json['platformModelName'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  isStreaming: json['isStreaming'] as bool? ?? false,
  error: json['error'] as String?,
  thinking: json['thinking'] as String? ?? '',
  processStatus: json['processStatus'] as String?,
  toolSummary: json['toolSummary'] as String?,
  myFeedback: json['myFeedback'] as String?,
  parentPublicID: json['parentPublicID'] as String?,
  sourcePublicID: json['sourcePublicID'] as String?,
  branchReason: json['branchReason'] as String?,
  ragSummary: json['ragSummary'] as String?,
  fileProcMessage: json['fileProcMessage'] as String?,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serverMessageID': instance.serverMessageID,
      'role': _$MessageRoleEnumMap[instance.role]!,
      'content': instance.content,
      'contentType': instance.contentType,
      'runID': instance.runID,
      'status': instance.status,
      'platformModelName': instance.platformModelName,
      'createdAt': instance.createdAt?.toIso8601String(),
      'isStreaming': instance.isStreaming,
      'error': instance.error,
      'thinking': instance.thinking,
      'processStatus': instance.processStatus,
      'toolSummary': instance.toolSummary,
      'myFeedback': instance.myFeedback,
      'parentPublicID': instance.parentPublicID,
      'sourcePublicID': instance.sourcePublicID,
      'branchReason': instance.branchReason,
      'ragSummary': instance.ragSummary,
      'fileProcMessage': instance.fileProcMessage,
    };

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
  MessageRole.system: 'system',
  MessageRole.tool: 'tool',
  MessageRole.unknown: 'unknown',
};
