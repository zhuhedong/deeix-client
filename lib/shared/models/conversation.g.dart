// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    _Conversation(
      publicID: json['publicID'] as String,
      title: json['title'] as String?,
      model: json['model'] as String?,
      status: json['status'] as String?,
      isStarred: json['isStarred'] as bool? ?? false,
      messageCount: (json['messageCount'] as num?)?.toInt(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      projectID: json['projectID'] as String?,
      projectName: json['projectName'] as String?,
    );

Map<String, dynamic> _$ConversationToJson(_Conversation instance) =>
    <String, dynamic>{
      'publicID': instance.publicID,
      'title': instance.title,
      'model': instance.model,
      'status': instance.status,
      'isStarred': instance.isStarred,
      'messageCount': instance.messageCount,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'projectID': instance.projectID,
      'projectName': instance.projectName,
    };
