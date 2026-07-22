import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
abstract class Conversation with _$Conversation {
  const factory Conversation({
    /// API path id — ConversationResponse.publicID
    required String publicID,
    String? title,
    String? model,
    String? status,
    @Default(false) bool isStarred,
    int? messageCount,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? projectID,
    String? projectName,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  /// Maps `ConversationResponse`.
  factory Conversation.fromApi(Map<String, dynamic> json) {
    DateTime? parseTime(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    final publicID = '${json['publicID'] ?? json['public_id'] ?? ''}'.trim();

    return Conversation(
      publicID: publicID,
      title: json['title'] as String?,
      model: json['model'] as String?,
      status: json['status'] as String?,
      isStarred: json['isStarred'] == true || json['is_starred'] == true,
      messageCount: json['messageCount'] is int
          ? json['messageCount'] as int
          : int.tryParse('${json['messageCount'] ?? ''}'),
      updatedAt: parseTime(json['updatedAt'] ?? json['updated_at']),
      createdAt: parseTime(json['createdAt'] ?? json['created_at']),
      projectID: json['projectID'] as String?,
      projectName: json['projectName'] as String?,
    );
  }

  const Conversation._();

  /// Prefer non-empty title for UI.
  String get displayTitle {
    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;
    return '新对话';
  }
}
