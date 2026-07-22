import 'dart:convert';

/// One file attached to a chat message (parsed from MessageResponse.attachments).
///
/// Wire format (web client `parseAttachments`): JSON **string** of array items
/// with snake_case keys (`file_id`, `file_name`, `mime_type`, …).
class MessageAttachment {
  const MessageAttachment({
    required this.fileID,
    this.fileName = '',
    this.mimeType = '',
    this.fileCategory = '',
    this.sizeBytes = 0,
    this.kind = 'file',
    this.processingReady = false,
    this.localPath,
  });

  final String fileID;
  final String fileName;
  final String mimeType;
  final String fileCategory;
  final int sizeBytes;
  final String kind;
  final bool processingReady;

  /// Local path for optimistic UI before server final message arrives.
  final String? localPath;

  bool get isImage {
    if (kind == 'image') return true;
    if (mimeType.startsWith('image/')) return true;
    if (fileCategory.toLowerCase().contains('image')) return true;
    final name = fileName.toLowerCase();
    return name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp') ||
        name.endsWith('.heic');
  }

  bool get isPdf =>
      mimeType.toLowerCase() == 'application/pdf' ||
      fileName.toLowerCase().endsWith('.pdf');

  bool get isTextLike {
    final m = mimeType.toLowerCase();
    final n = fileName.toLowerCase();
    if (m.startsWith('text/')) return true;
    if (m.contains('json') || m.contains('xml') || m.contains('markdown')) {
      return true;
    }
    return n.endsWith('.txt') ||
        n.endsWith('.md') ||
        n.endsWith('.json') ||
        n.endsWith('.csv') ||
        n.endsWith('.log') ||
        n.endsWith('.yaml') ||
        n.endsWith('.yml') ||
        n.endsWith('.xml');
  }

  bool get canInAppPreview => isImage || isPdf || isTextLike;

  String get processingLabel {
    if (processingReady) return '已就绪';
    return '';
  }

  MessageAttachment copyWith({String? localPath, bool? processingReady}) {
    return MessageAttachment(
      fileID: fileID,
      fileName: fileName,
      mimeType: mimeType,
      fileCategory: fileCategory,
      sizeBytes: sizeBytes,
      kind: kind,
      processingReady: processingReady ?? this.processingReady,
      localPath: localPath ?? this.localPath,
    );
  }

  factory MessageAttachment.fromMap(Map<String, dynamic> json) {
    final fileID =
        '${json['fileID'] ?? json['file_id'] ?? json['fileId'] ?? ''}'.trim();
    final mime =
        '${json['mimeType'] ?? json['mime_type'] ?? json['detectedMime'] ?? json['detected_mime'] ?? ''}';
    final category = '${json['fileCategory'] ?? json['file_category'] ?? ''}';
    final kindRaw = '${json['kind'] ?? ''}';
    final kind = kindRaw == 'image' || mime.startsWith('image/')
        ? 'image'
        : (kindRaw.isEmpty ? 'file' : kindRaw);
    final size = json['sizeBytes'] ?? json['file_size'] ?? json['size'] ?? 0;

    return MessageAttachment(
      fileID: fileID,
      fileName:
          '${json['fileName'] ?? json['file_name'] ?? json['name'] ?? ''}',
      mimeType: mime,
      fileCategory: category,
      sizeBytes: size is int ? size : int.tryParse('$size') ?? 0,
      kind: kind,
      processingReady:
          json['processingReady'] == true || json['processing_ready'] == true,
    );
  }

  /// Parses MessageResponse.attachments (JSON string, List, or null).
  static List<MessageAttachment> parseAttachments(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => MessageAttachment.fromMap(Map<String, dynamic>.from(e)))
          .where((a) => a.fileID.isNotEmpty || a.localPath != null)
          .toList();
    }
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty || s == 'null') return const [];
      try {
        final decoded = jsonDecode(s);
        return parseAttachments(decoded);
      } catch (_) {
        return const [];
      }
    }
    if (raw is Map) {
      final one = MessageAttachment.fromMap(Map<String, dynamic>.from(raw));
      return one.fileID.isEmpty ? const [] : [one];
    }
    return const [];
  }
}
