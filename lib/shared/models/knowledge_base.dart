/// Knowledge base (DEEIX-Chat 0.4.4+). `scope` is `builtin` (admin-managed,
/// read-only for users) or `user` (owned by the current user).
class KnowledgeBase {
  const KnowledgeBase({
    required this.publicID,
    required this.name,
    this.scope = 'user',
    this.description = '',
    this.enabled = true,
    this.fileCount = 0,
    this.readyFileCount = 0,
    this.processingFileCount = 0,
    this.updatedAt,
  });

  final String publicID;
  final String name;
  final String scope;
  final String description;
  final bool enabled;
  final int fileCount;
  final int readyFileCount;
  final int processingFileCount;
  final DateTime? updatedAt;

  bool get isMine => scope == 'user';

  factory KnowledgeBase.fromApi(Map<String, dynamic> json) {
    return KnowledgeBase(
      publicID: '${json['publicID'] ?? ''}',
      name: '${json['name'] ?? ''}',
      scope: '${json['scope'] ?? 'user'}',
      description: '${json['description'] ?? ''}',
      enabled: json['enabled'] != false,
      fileCount: _int(json['fileCount']),
      readyFileCount: _int(json['readyFileCount']),
      processingFileCount: _int(json['processingFileCount']),
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    );
  }
}

class KnowledgeBaseFile {
  const KnowledgeBaseFile({
    required this.fileID,
    required this.fileName,
    this.mimeType = '',
    this.sizeBytes = 0,
    this.processingStatus = '',
    this.processing = false,
    this.processingReady = false,
    this.embedError = '',
    this.chunkCount = 0,
  });

  final String fileID;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String processingStatus;
  final bool processing;
  final bool processingReady;
  final String embedError;
  final int chunkCount;

  /// Short Chinese status label for list rows.
  String get statusLabel {
    if (embedError.isNotEmpty) return '处理失败';
    if (processingReady) return '已就绪 · $chunkCount 段';
    if (processing) return '处理中';
    return processingStatus.isEmpty ? '等待处理' : processingStatus;
  }

  factory KnowledgeBaseFile.fromApi(Map<String, dynamic> json) {
    return KnowledgeBaseFile(
      fileID: '${json['fileID'] ?? ''}',
      fileName: '${json['fileName'] ?? ''}',
      mimeType: '${json['mimeType'] ?? ''}',
      sizeBytes: _int(json['sizeBytes']),
      processingStatus: '${json['processingStatus'] ?? ''}',
      processing: json['processing'] == true,
      processingReady: json['processingReady'] == true,
      embedError: '${json['embedError'] ?? ''}',
      chunkCount: _int(json['chunkCount']),
    );
  }
}

int _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
