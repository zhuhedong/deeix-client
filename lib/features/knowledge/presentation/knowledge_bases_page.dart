import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/knowledge_base.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../file/data/file_repository.dart';
import '../data/knowledge_repository.dart';

/// Lists built-in + personal knowledge bases (DEEIX-Chat 0.4.4+).
class KnowledgeBasesPage extends ConsumerStatefulWidget {
  const KnowledgeBasesPage({super.key});

  @override
  ConsumerState<KnowledgeBasesPage> createState() => _KnowledgeBasesPageState();
}

class _KnowledgeBasesPageState extends ConsumerState<KnowledgeBasesPage> {
  late Future<List<KnowledgeBase>> _future = _load();

  Future<List<KnowledgeBase>> _load() async {
    final repo = await ref.read(knowledgeRepositoryProvider.future);
    return repo.listVisible();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    ref.invalidate(visibleKnowledgeBasesProvider);
  }

  Future<void> _edit([KnowledgeBase? kb]) async {
    final result = await showKnowledgeBaseEditor(context, kb);
    if (result == null) return;
    try {
      final repo = await ref.read(knowledgeRepositoryProvider.future);
      if (kb == null) {
        await repo.create(name: result.name, description: result.description);
      } else {
        await repo.update(
          kb.publicID,
          name: result.name,
          description: result.description,
        );
      }
      await _reload();
    } catch (e) {
      _toast('$e');
    }
  }

  Future<void> _delete(KnowledgeBase kb) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除知识库'),
        content: Text('确定删除「${kb.name}」？库中的文件索引会一并删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final repo = await ref.read(knowledgeRepositoryProvider.future);
      await repo.delete(kb.publicID);
      await _reload();
    } catch (e) {
      _toast('$e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建'),
      ),
      body: FutureBuilder<List<KnowledgeBase>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: '加载知识库…');
          }
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}', onRetry: _reload);
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.library_books_outlined,
              title: '还没有知识库',
              message: '新建一个知识库并上传文档，聊天时即可选择它作为检索来源。',
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final kb = items[i];
                return ListTile(
                  leading: Icon(
                    kb.isMine
                        ? Icons.library_books_outlined
                        : Icons.verified_outlined,
                  ),
                  title: Text(kb.name),
                  subtitle: Text(
                    [
                      kb.isMine ? '我的' : '内置',
                      '${kb.readyFileCount}/${kb.fileCount} 个文件就绪',
                      if (kb.processingFileCount > 0)
                        '${kb.processingFileCount} 个处理中',
                      if (kb.description.isNotEmpty) kb.description,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: kb.isMine
                      ? PopupMenuButton<String>(
                          onSelected: (v) =>
                              v == 'edit' ? _edit(kb) : _delete(kb),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('编辑')),
                            PopupMenuItem(value: 'delete', child: Text('删除')),
                          ],
                        )
                      : null,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => KnowledgeBaseDetailPage(kb: kb),
                      ),
                    );
                    await _reload();
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

Future<({String name, String description})?> showKnowledgeBaseEditor(
  BuildContext context,
  KnowledgeBase? kb,
) {
  final name = TextEditingController(text: kb?.name ?? '');
  final desc = TextEditingController(text: kb?.description ?? '');
  return showDialog<({String name, String description})>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(kb == null ? '新建知识库' : '编辑知识库'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            maxLength: 80,
            autofocus: true,
            decoration: const InputDecoration(labelText: '名称'),
          ),
          TextField(
            controller: desc,
            maxLength: 255,
            decoration: const InputDecoration(labelText: '描述（可选）'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (name.text.trim().isEmpty) return;
            Navigator.pop(ctx, (name: name.text, description: desc.text));
          },
          child: const Text('保存'),
        ),
      ],
    ),
  ).whenComplete(() {
    name.dispose();
    desc.dispose();
  });
}

/// Files of one knowledge base; personal ones can add / remove files.
class KnowledgeBaseDetailPage extends ConsumerStatefulWidget {
  const KnowledgeBaseDetailPage({super.key, required this.kb});

  final KnowledgeBase kb;

  @override
  ConsumerState<KnowledgeBaseDetailPage> createState() =>
      _KnowledgeBaseDetailPageState();
}

class _KnowledgeBaseDetailPageState
    extends ConsumerState<KnowledgeBaseDetailPage> {
  late Future<List<KnowledgeBaseFile>> _future = _load();
  bool _busy = false;

  Future<List<KnowledgeBaseFile>> _load() async {
    final repo = await ref.read(knowledgeRepositoryProvider.future);
    return repo.listFiles(widget.kb.publicID);
  }

  Future<void> _reload() async => setState(() => _future = _load());

  Future<void> _run(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _uploadNew() async {
    final picked = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (picked == null) return;
    await _run(() async {
      final files = await ref.read(fileRepositoryProvider.future);
      final ids = <String>[];
      for (final f in picked.files) {
        if (f.path == null) continue;
        final obj = await files.upload(file: File(f.path!), fileName: f.name);
        if (obj.fileID.isNotEmpty) ids.add(obj.fileID);
      }
      final repo = await ref.read(knowledgeRepositoryProvider.future);
      await repo.addFiles(widget.kb.publicID, ids);
    });
  }

  Future<void> _addExisting() async {
    final repo = await ref.read(knowledgeRepositoryProvider.future);
    final List<KnowledgeBaseFile> available;
    try {
      available = await repo.listAvailableFiles(widget.kb.publicID);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    if (!mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可添加的已上传文件')));
      return;
    }
    final chosen = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        final sel = <String>{};
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('从我的文件添加'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final f in available)
                    CheckboxListTile(
                      value: sel.contains(f.fileID),
                      title: Text(f.fileName, overflow: TextOverflow.ellipsis),
                      onChanged: (v) => setLocal(
                        () => v == true
                            ? sel.add(f.fileID)
                            : sel.remove(f.fileID),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, sel),
                child: const Text('添加'),
              ),
            ],
          ),
        );
      },
    );
    if (chosen == null || chosen.isEmpty) return;
    await _run(() => repo.addFiles(widget.kb.publicID, chosen.toList()));
  }

  @override
  Widget build(BuildContext context) {
    final mine = widget.kb.isMine;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.kb.name),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (mine)
            PopupMenuButton<String>(
              icon: const Icon(Icons.add_rounded),
              tooltip: '添加文件',
              enabled: !_busy,
              onSelected: (v) => v == 'upload' ? _uploadNew() : _addExisting(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'upload', child: Text('上传新文件')),
                PopupMenuItem(value: 'existing', child: Text('从我的文件添加')),
              ],
            ),
        ],
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: FutureBuilder<List<KnowledgeBaseFile>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: '加载文件…');
          }
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}', onRetry: _reload);
          }
          final files = snap.data ?? const [];
          if (files.isEmpty) {
            return EmptyState(
              icon: Icons.description_outlined,
              title: '知识库里还没有文件',
              message: mine ? '点右上角 + 上传文档，处理完成后即可用于检索。' : null,
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              itemCount: files.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final f = files[i];
                return ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(f.fileName, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    f.embedError.isNotEmpty
                        ? '${f.statusLabel}：${f.embedError}'
                        : f.statusLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: mine
                      ? IconButton(
                          tooltip: '移出知识库',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  final repo = await ref.read(
                                    knowledgeRepositoryProvider.future,
                                  );
                                  await repo.removeFile(
                                    widget.kb.publicID,
                                    f.fileID,
                                  );
                                }),
                        )
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
