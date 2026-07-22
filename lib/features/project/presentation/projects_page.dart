import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/project.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../data/project_repository.dart';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> {
  late Future<List<ConversationProject>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ConversationProject>> _load() async {
    final repo = await ref.read(projectRepositoryProvider.future);
    return repo.list();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
  }

  Future<void> _create() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建项目'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名称'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    final repo = await ref.read(projectRepositoryProvider.future);
    await repo.create(name: name);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目分组'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        tooltip: '新建项目',
        child: const Icon(Icons.add_rounded),
      ),
      body: FutureBuilder<List<ConversationProject>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: '加载项目…');
          }
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}', onRetry: _reload);
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.folder_special_outlined,
              title: '还没有项目',
              message: '用项目把相关对话归到一起，便于查找。',
              action: FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('新建项目'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = items[i];
                final label = p.icon.isNotEmpty ? p.icon : p.name;
                final initial = label.isEmpty
                    ? '#'
                    : label.substring(0, 1).toUpperCase();
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
                    leading: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: context.tokens.brandLinearGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        initial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(p.name, style: theme.textTheme.titleSmall),
                    subtitle: p.description.isEmpty
                        ? null
                        : Text(p.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: theme.colorScheme.onSurfaceVariant,
                      onPressed: () => _confirmDelete(context, p),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ConversationProject p,
  ) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除项目'),
            content: Text('删除「${p.name}」？其中的对话不会被删除。'),
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
    final repo = await ref.read(projectRepositoryProvider.future);
    await repo.delete(p.publicID);
    await _reload();
  }
}
