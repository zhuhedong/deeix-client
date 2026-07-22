import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/auth_network_image.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/file_preview_page.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../data/file_repository.dart';

class FilesPage extends ConsumerStatefulWidget {
  const FilesPage({super.key});

  @override
  ConsumerState<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends ConsumerState<FilesPage> {
  late Future<FileListPage> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<FileListPage> _load() async {
    final repo = await ref.read(fileRepositoryProvider.future);
    return repo.list();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的文件'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<FileListPage>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: '加载文件…');
          }
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}', onRetry: _reload);
          }
          final items = snap.data!.results;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open_outlined,
              title: '还没有文件',
              message: '在聊天中发送的图片和文档会出现在这里。',
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final f = items[i];
                final proc = f.processingLabel;
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.tokens.hairline),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: f.isImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: AuthNetworkImage(fileId: f.fileID),
                            ),
                          )
                        : IconBadge(
                            icon: f.isPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.insert_drive_file_outlined,
                          ),
                    title: Text(
                      f.fileName.isEmpty ? f.fileID : f.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      [
                        if (f.mimeType.isNotEmpty) f.mimeType,
                        '${(f.sizeBytes / 1024).toStringAsFixed(1)} KB',
                        if (proc.isNotEmpty) proc,
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: theme.colorScheme.onSurfaceVariant,
                      onPressed: () => _confirmDelete(context, f),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FilePreviewPage.fromFileObject(f),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, dynamic f) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除文件'),
            content: Text('删除 ${f.fileName}？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('删除'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    final repo = await ref.read(fileRepositoryProvider.future);
    await repo.delete(f.fileID);
    await _reload();
  }
}
