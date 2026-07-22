class ConversationShare {
  const ConversationShare({
    required this.shareID,
    this.status = '',
    this.titleSnapshot,
    this.modelSnapshot,
    this.messageCount = 0,
    this.createdAt,
    this.revokedAt,
  });

  final String shareID;
  final String status;
  final String? titleSnapshot;
  final String? modelSnapshot;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? revokedAt;

  bool get isActive =>
      status.toLowerCase() == 'active' ||
      status.toLowerCase() == 'shared' ||
      (shareID.isNotEmpty && revokedAt == null);

  /// Public web URL for the share (origin + path used by DEEIX web).
  String publicUrl(String webBase) {
    final base = webBase.endsWith('/')
        ? webBase.substring(0, webBase.length - 1)
        : webBase;
    return '$base/share/$shareID';
  }

  factory ConversationShare.fromApi(Map<String, dynamic> json) {
    DateTime? t(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return ConversationShare(
      shareID: '${json['shareID'] ?? json['share_id'] ?? ''}',
      status: '${json['status'] ?? ''}',
      titleSnapshot: json['titleSnapshot'] as String?,
      modelSnapshot: json['modelSnapshot'] as String?,
      messageCount: json['messageCount'] is int
          ? json['messageCount'] as int
          : int.tryParse('${json['messageCount'] ?? 0}') ?? 0,
      createdAt: t(json['createdAt']),
      revokedAt: t(json['revokedAt']),
    );
  }
}
