import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../features/file/data/file_repository.dart';
import '../models/file_object.dart';
import '../models/message_attachment.dart';
import 'auth_network_image.dart';

/// In-app preview for chat attachments / library files (image, PDF, text).
class FilePreviewPage extends ConsumerStatefulWidget {
  const FilePreviewPage({
    super.key,
    this.fileId,
    this.fileName = '',
    this.mimeType = '',
    this.localPath,
    this.processingLabel,
  });

  final String? fileId;
  final String fileName;
  final String mimeType;
  final String? localPath;
  final String? processingLabel;

  factory FilePreviewPage.fromAttachment(MessageAttachment a) {
    return FilePreviewPage(
      fileId: a.fileID.isEmpty ? null : a.fileID,
      fileName: a.fileName,
      mimeType: a.mimeType,
      localPath: a.localPath,
      processingLabel: a.processingLabel.isEmpty ? null : a.processingLabel,
    );
  }

  factory FilePreviewPage.fromFileObject(FileObject f) {
    return FilePreviewPage(
      fileId: f.fileID,
      fileName: f.fileName,
      mimeType: f.mimeType,
      processingLabel: f.processingLabel.isEmpty ? null : f.processingLabel,
    );
  }

  @override
  ConsumerState<FilePreviewPage> createState() => _FilePreviewPageState();
}

class _FilePreviewPageState extends ConsumerState<FilePreviewPage> {
  late Future<_PreviewPayload> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  bool get _isImage {
    final m = widget.mimeType.toLowerCase();
    final n = widget.fileName.toLowerCase();
    if (m.startsWith('image/')) return true;
    return n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.gif') ||
        n.endsWith('.webp') ||
        n.endsWith('.heic');
  }

  bool get _isPdf {
    final m = widget.mimeType.toLowerCase();
    final n = widget.fileName.toLowerCase();
    return m == 'application/pdf' || n.endsWith('.pdf');
  }

  bool get _isText {
    final m = widget.mimeType.toLowerCase();
    final n = widget.fileName.toLowerCase();
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

  Future<_PreviewPayload> _load() async {
    if (widget.localPath != null &&
        widget.localPath!.isNotEmpty &&
        File(widget.localPath!).existsSync()) {
      final path = widget.localPath!;
      if (_isText) {
        final text = await File(path).readAsString();
        return _PreviewPayload.text(text);
      }
      if (_isPdf || !_isImage) {
        return _PreviewPayload.filePath(path);
      }
      return _PreviewPayload.localImage(path);
    }

    final id = widget.fileId;
    if (id == null || id.isEmpty) {
      throw StateError('no file id or local path');
    }

    final repo = await ref.read(fileRepositoryProvider.future);

    if (_isImage) {
      return _PreviewPayload.remoteImage(id);
    }

    if (_isText) {
      final bytes = await repo.downloadContent(id);
      final text = utf8.decode(bytes, allowMalformed: true);
      return _PreviewPayload.text(text);
    }

    // PDF and other binaries → temp path for viewer / external open.
    final path = await repo.downloadToTemp(
      id,
      fileName: widget.fileName.isEmpty
          ? (_isPdf ? '$id.pdf' : id)
          : widget.fileName,
    );
    return _PreviewPayload.filePath(path);
  }

  Future<void> _openExternal(String path) async {
    final result = await OpenFilex.open(path);
    if (!mounted) return;
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法打开: ${result.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.fileName.isEmpty
        ? (widget.fileId ?? '文件预览')
        : widget.fileName;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.processingLabel != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Chip(
                  label: Text(
                    widget.processingLabel!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<_PreviewPayload>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '预览失败: ${snap.error ?? 'unknown'}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snap.data!;
          switch (data.kind) {
            case _PreviewKind.remoteImage:
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(
                  child: AuthNetworkImage(
                    fileId: data.fileId!,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            case _PreviewKind.localImage:
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(
                  child: Image.file(File(data.path!), fit: BoxFit.contain),
                ),
              );
            case _PreviewKind.text:
              return SelectionArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    data.text ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),
              );
            case _PreviewKind.filePath:
              if (_isPdf) {
                return Column(
                  children: [
                    Expanded(
                      child: PdfViewer.file(
                        data.path!,
                        params: const PdfViewerParams(margin: 8),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: OutlinedButton.icon(
                          onPressed: () => _openExternal(data.path!),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('用系统应用打开'),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return _GenericFileBody(
                fileName: title,
                mimeType: widget.mimeType,
                path: data.path!,
                onOpen: () => _openExternal(data.path!),
              );
          }
        },
      ),
    );
  }
}

class _GenericFileBody extends StatelessWidget {
  const _GenericFileBody({
    required this.fileName,
    required this.mimeType,
    required this.path,
    required this.onOpen,
  });

  final String fileName;
  final String mimeType;
  final String path;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final size = File(path).existsSync() ? File(path).lengthSync() : 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              fileName,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (mimeType.isNotEmpty) mimeType,
                if (size > 0) '${(size / 1024).toStringAsFixed(1)} KB',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('打开文件'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PreviewKind { remoteImage, localImage, text, filePath }

class _PreviewPayload {
  const _PreviewPayload._({
    required this.kind,
    this.fileId,
    this.path,
    this.text,
  });

  factory _PreviewPayload.remoteImage(String fileId) =>
      _PreviewPayload._(kind: _PreviewKind.remoteImage, fileId: fileId);

  factory _PreviewPayload.localImage(String path) =>
      _PreviewPayload._(kind: _PreviewKind.localImage, path: path);

  factory _PreviewPayload.text(String text) =>
      _PreviewPayload._(kind: _PreviewKind.text, text: text);

  factory _PreviewPayload.filePath(String path) =>
      _PreviewPayload._(kind: _PreviewKind.filePath, path: path);

  final _PreviewKind kind;
  final String? fileId;
  final String? path;
  final String? text;
}

/// Opens [FilePreviewPage] via Navigator.
Future<void> openFilePreview(
  BuildContext context, {
  String? fileId,
  String fileName = '',
  String mimeType = '',
  String? localPath,
  String? processingLabel,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FilePreviewPage(
        fileId: fileId,
        fileName: fileName,
        mimeType: mimeType,
        localPath: localPath,
        processingLabel: processingLabel,
      ),
    ),
  );
}
