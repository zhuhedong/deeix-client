import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/conversation.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../conversation/data/conversation_repository.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  Future<List<Conversation>>? _future;
  String _lastQuery = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<List<Conversation>> _search(String q) async {
    final repo = await ref.read(conversationRepositoryProvider.future);
    // Search active + archived for better coverage.
    final active = await repo.listPage(
      page: 1,
      pageSize: 50,
      status: 'all',
      query: q,
    );
    return active.results;
  }

  void _run() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _lastQuery = q;
      _future = _search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('全局搜索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '搜索会话标题 / 消息内容…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: '搜索',
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: _run,
                ),
              ),
              onSubmitted: (_) => _run(),
            ),
          ),
          Expanded(
            child: _future == null
                ? const EmptyState(
                    icon: Icons.search_rounded,
                    title: '搜索你的对话',
                    message: '按标题或消息内容查找历史会话。',
                  )
                : FutureBuilder<List<Conversation>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return LoadingView(message: '搜索 “$_lastQuery”…');
                      }
                      if (snap.hasError) {
                        return ErrorView(
                          message: '${snap.error}',
                          onRetry: _run,
                        );
                      }
                      final items = snap.data ?? const [];
                      if (items.isEmpty) {
                        return EmptyState(
                          icon: Icons.search_off_rounded,
                          title: '没有结果',
                          message: '未找到与 “$_lastQuery” 相关的会话。',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = items[i];
                          final time = c.updatedAt ?? c.createdAt;
                          return Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: context.tokens.hairline,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: const IconBadge(
                                icon: Icons.chat_bubble_outline_rounded,
                              ),
                              title: Text(
                                c.displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                              subtitle: Text(
                                [
                                  if (c.model != null && c.model!.isNotEmpty)
                                    c.model!,
                                  if (c.projectName != null &&
                                      c.projectName!.isNotEmpty)
                                    c.projectName!,
                                  if (time != null) fmt.format(time.toLocal()),
                                ].join('  ·  '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => context.push('/chat/${c.publicID}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
