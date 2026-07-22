import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_object.freezed.dart';
part 'file_object.g.dart';

@freezed
abstract class FileObject with _$FileObject {
  const factory FileObject({
    required String fileID,
    @Default('') String fileName,
    @Default('') String mimeType,
    @Default(0) int sizeBytes,
    @Default('') String status,
    @Default('') String fileCategory,
    String? purpose,
    @Default(false) bool processingReady,
    @Default('') String processingStatus,
    @Default('') String extractStatus,
    @Default('') String embedStatus,
    String? processingErrorMessage,
  }) = _FileObject;

  factory FileObject.fromJson(Map<String, dynamic> json) =>
      _$FileObjectFromJson(json);

  factory FileObject.fromApi(Map<String, dynamic> json) {
    return FileObject(
      fileID: '${json['fileID'] ?? ''}',
      fileName: '${json['fileName'] ?? ''}',
      mimeType: '${json['mimeType'] ?? json['detectedMIME'] ?? ''}',
      sizeBytes: json['sizeBytes'] is int
          ? json['sizeBytes'] as int
          : int.tryParse('${json['sizeBytes'] ?? 0}') ?? 0,
      status: '${json['status'] ?? ''}',
      fileCategory: '${json['fileCategory'] ?? ''}',
      purpose: json['purpose'] as String?,
      processingReady: json['processingReady'] == true,
      processingStatus: '${json['processingStatus'] ?? ''}',
      extractStatus: '${json['extractStatus'] ?? ''}',
      embedStatus: '${json['embedStatus'] ?? ''}',
      processingErrorMessage:
          (json['processingErrorMessage'] as String?)?.isNotEmpty == true
          ? json['processingErrorMessage'] as String
          : null,
    );
  }

  const FileObject._();

  bool get isImage =>
      mimeType.startsWith('image/') ||
      fileCategory.toLowerCase().contains('image');

  bool get isPdf =>
      mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

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

  /// Short OCR / RAG processing label for UI chips.
  String get processingLabel {
    if (processingErrorMessage != null && processingErrorMessage!.isNotEmpty) {
      return '处理失败';
    }
    if (processingReady) return '已就绪';
    final p = processingStatus.toLowerCase();
    final e = extractStatus.toLowerCase();
    final emb = embedStatus.toLowerCase();
    if (p.contains('fail') || e.contains('fail') || emb.contains('fail')) {
      return '处理失败';
    }
    if (e.contains('run') || e.contains('pend') || e.contains('process')) {
      return 'OCR 中';
    }
    if (emb.contains('run') ||
        emb.contains('pend') ||
        emb.contains('process')) {
      return '索引中';
    }
    if (p.isNotEmpty && p != 'ready' && p != 'done' && p != 'completed') {
      return processingStatus;
    }
    if (!processingReady && (e.isNotEmpty || emb.isNotEmpty || p.isNotEmpty)) {
      return '处理中';
    }
    return status.isNotEmpty ? status : '';
  }
}
