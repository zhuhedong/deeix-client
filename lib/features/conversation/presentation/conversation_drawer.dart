import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/settings/app_preferences.dart';
import '../../../shared/l10n/app_l10n.dart';
import '../../../shared/models/conversation.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../chat/presentation/chat_controller.dart';
import '../../project/data/project_repository.dart';
import '../data/conversation_repository.dart';
import 'conversation_controller.dart';

/// Side drawer holding the conversation history + primary navigation.
///
/// This is the app's main navigation surface now that the home screen opens
/// straight into a chat. It carries everything the old list page did: search,
/// active/archived filter, pagination and the full per-chat action menu.
class ChatDrawer extends ConsumerStatefulWidget {
  const ChatDrawer({super.key, this.activeConversationId});

  final String? activeConversationId;

  @override
  ConsumerState<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends ConsumerState<ChatDrawer> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref.read(conversationListProvider.notifier).loadMore();
    }
  }

  void _open(String conversationId) {
    Navigator.of(context).pop(); // close drawer
    context.go('/chat/$conversationId');
  }

  void _createChat() {
    // Start a fresh empty draft session on the home route.
    Navigator.of(context).pop(); // close drawer
    ref.read(chatControllerProvider('').notifier).resetDraft();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppL10n.of(context);
    final state = ref.watch(conversationListProvider);
    final user = ref.watch(authControllerProvider).user;
    final width = (MediaQuery.sizeOf(context).width * 0.86).clamp(280.0, 380.0);

    return Drawer(
      width: width,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
                  child: Row(
                    children: [
                      const BrandMark(size: 28),
                      const SizedBox(width: 10),
                      Text('DEEIX', style: theme.textTheme.titleLarge),
                      const Spacer(),
                      IconButton(
                        tooltip: '设置',
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push('/settings');
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: GradientButton(
                    height: 46,
                    icon: Icons.add_rounded,
                    onPressed: _createChat,
                    child: Text(l10n.newChat),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: l10n.searchChats,
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      suffixIcon: state.query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(conversationListProvider.notifier)
                                    .refresh(query: '');
                              },
                            ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => ref
                        .read(conversationListProvider.notifier)
                        .refresh(query: v.trim()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ConversationFilter>(
                      segments: [
                        ButtonSegment(
                          value: ConversationFilter.active,
                          label: Text(l10n.active),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 15,
                          ),
                        ),
                        ButtonSegment(
                          value: ConversationFilter.archived,
                          label: Text(l10n.archived),
                          icon: const Icon(Icons.archive_outlined, size: 15),
                        ),
                      ],
                      selected: {state.filter},
                      showSelectedIcon: false,
                      onSelectionChanged: (set) => ref
                          .read(conversationListProvider.notifier)
                          .setFilter(set.first),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildList(context, state, l10n)),
          const Divider(height: 1),
          if (user != null)
            SafeArea(
              top: false,
              child: ListTile(
                leading: const IconBadge(icon: Icons.person_rounded, size: 38),
                title: Text(
                  user.displayLabel,
                  style: theme.textTheme.titleSmall,
                ),
                subtitle: Text(
                  user.email ?? user.publicID ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/profile');
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    ConversationListState state,
    AppL10n l10n,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: SizedBox(
          height: 26,
          width: 26,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.filter == ConversationFilter.archived
                ? '暂无归档对话'
                : l10n.emptyChats,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final fmt = DateFormat('MM-dd HH:mm');
    final extra = state.isLoadingMore ? 1 : 0;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      itemCount: state.items.length + extra,
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        }
        final c = state.items[index];
        final time = c.updatedAt ?? c.createdAt;
        return _DrawerRow(
          conversation: c,
          active: c.publicID == widget.activeConversationId,
          isArchivedFilter: state.filter == ConversationFilter.archived,
          timeLabel: time == null ? null : fmt.format(time.toLocal()),
          onTap: () => _open(c.publicID),
          onMenu: (v) => _onMenuAction(v, c, l10n),
        );
      },
    );
  }

  // ---- per-conversation actions (ported from the old list page) ----

  Future<void> _onMenuAction(String value, Conversation c, AppL10n l10n) async {
    final notifier = ref.read(conversationListProvider.notifier);
    switch (value) {
      case 'rename':
        await _rename(c.publicID, c.title ?? '');
      case 'star':
        await notifier.toggleStar(c.publicID);
      case 'archive':
        await notifier.archive(c.publicID, archived: true);
        _toast(l10n.archivedToast);
      case 'unarchive':
        await notifier.archive(c.publicID, archived: false);
        _toast(l10n.unarchivedToast);
      case 'share':
        final url = await notifier.createShareLink(
          c.publicID,
          ref.read(serverBaseUrlProvider),
        );
        if (url != null) {
          await Clipboard.setData(ClipboardData(text: url));
          _toast('${l10n.shareCopied}\n$url');
        } else {
          _toast(l10n.shareFailed(ref.read(conversationListProvider).error));
        }
      case 'revoke_share':
        await notifier.revokeShare(c.publicID);
      case 'export':
        try {
          final repo = await ref.read(conversationRepositoryProvider.future);
          final data = await repo.export(c.publicID);
          final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
          await Clipboard.setData(ClipboardData(text: jsonStr));
          _toast('导出 JSON 已复制到剪贴板');
        } catch (e) {
          _toast('导出失败: $e');
        }
      case 'project':
        await _assignProject(c.publicID);
      case 'delete':
        await _confirmDelete(c, l10n);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete(Conversation c, AppL10n l10n) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.deleteChat),
            content: Text(l10n.deleteChatConfirm(c.displayTitle)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await ref.read(conversationListProvider.notifier).delete(c.publicID);
    }
  }

  Future<void> _rename(String publicId, String currentTitle) async {
    final l10n = AppL10n.of(context);
    final ctrl = TextEditingController(text: currentTitle);
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameChat),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.title),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (title == null || title.isEmpty) return;
    final ok = await ref
        .read(conversationListProvider.notifier)
        .rename(publicId, title);
    if (!ok) {
      _toast(l10n.renameFailed(ref.read(conversationListProvider).error));
    }
  }

  Future<void> _assignProject(String conversationId) async {
    try {
      final repo = await ref.read(projectRepositoryProvider.future);
      final projects = await repo.list();
      if (!mounted) return;
      final selected = await showModalBottomSheet<String?>(
        context: context,
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('设置项目归属')),
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('无项目'),
                onTap: () => Navigator.pop(ctx, ''),
              ),
              ...projects.map(
                (p) => ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(p.name),
                  subtitle: p.description.isEmpty ? null : Text(p.description),
                  onTap: () => Navigator.pop(ctx, p.publicID),
                ),
              ),
            ],
          ),
        ),
      );
      if (selected == null) return;
      final convRepo = await ref.read(conversationRepositoryProvider.future);
      await convRepo.setProject(
        conversationId,
        selected.isEmpty ? null : selected,
      );
      _toast('项目已更新');
    } catch (e) {
      _toast('设置项目失败: $e');
    }
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.conversation,
    required this.active,
    required this.isArchivedFilter,
    required this.timeLabel,
    required this.onTap,
    required this.onMenu,
  });

  final Conversation conversation;
  final bool active;
  final bool isArchivedFilter;
  final String? timeLabel;
  final VoidCallback onTap;
  final ValueChanged<String> onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final c = conversation;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? tokens.softAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              children: [
                Icon(
                  c.isStarred
                      ? Icons.star_rounded
                      : Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: c.isStarred || active
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: active ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                      if ((c.model ?? '').isNotEmpty || timeLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            [
                              if ((c.model ?? '').isNotEmpty) c.model!,
                              ?timeLabel,
                            ].join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  onSelected: onMenu,
                  itemBuilder: (ctx) {
                    final l10n = AppL10n.of(ctx);
                    return [
                      _mi('rename', Icons.edit_outlined, l10n.rename),
                      _mi(
                        'star',
                        c.isStarred ? Icons.star : Icons.star_outline_rounded,
                        c.isStarred ? l10n.unpin : l10n.pin,
                      ),
                      if (isArchivedFilter)
                        _mi(
                          'unarchive',
                          Icons.unarchive_outlined,
                          l10n.unarchive,
                        )
                      else
                        _mi('archive', Icons.archive_outlined, l10n.archive),
                      _mi('share', Icons.link_rounded, l10n.shareLink),
                      _mi('project', Icons.folder_outlined, '设置项目'),
                      _mi('export', Icons.ios_share_rounded, '导出 JSON'),
                      _mi(
                        'delete',
                        Icons.delete_outline_rounded,
                        l10n.delete,
                        danger: true,
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _mi(
    String value,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Builder(
        builder: (context) {
          final color = danger
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurface;
          return Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: color)),
            ],
          );
        },
      ),
    );
  }
}
