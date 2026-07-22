import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/models/session.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../data/sessions_repository.dart';
import 'auth_controller.dart';

class SessionsPage extends ConsumerStatefulWidget {
  const SessionsPage({super.key});

  @override
  ConsumerState<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends ConsumerState<SessionsPage> {
  late Future<List<ActiveSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ActiveSession>> _load() async {
    final repo = await ref.read(sessionsRepositoryProvider.future);
    return repo.list();
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('活跃设备'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          TextButton(
            onPressed: _logoutAll,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('全部退出'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<List<ActiveSession>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: '加载会话…');
          }
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}', onRetry: _reload);
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.devices_other_rounded,
              title: '没有活跃会话',
              message: '登录后的设备会显示在这里。',
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = items[i];
                final seen = s.lastSeenAt ?? s.createdAt;
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: s.current
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : context.tokens.hairline,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: IconBadge(
                      icon: s.current
                          ? Icons.smartphone_rounded
                          : Icons.devices_other_rounded,
                      gradient: s.current,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            s.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (s.current) ...[
                          const SizedBox(width: 8),
                          _CurrentTag(),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      [
                        if (s.locationLabel.isNotEmpty) s.locationLabel,
                        if (s.clientIP.isNotEmpty) s.clientIP,
                        if (seen != null) fmt.format(seen.toLocal()),
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: s.current
                        ? null
                        : IconButton(
                            tooltip: '踢出设备',
                            icon: const Icon(Icons.logout_rounded),
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: () async {
                              final repo = await ref.read(
                                sessionsRepositoryProvider.future,
                              );
                              await repo.logoutSession(s.sessionID);
                              await _reload();
                            },
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

  Future<void> _logoutAll() async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('退出全部设备'),
            content: const Text('将注销所有会话（含本机），需要重新登录。'),
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
                child: const Text('确认退出'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    final repo = await ref.read(sessionsRepositoryProvider.future);
    await repo.logoutAll();
    await ref.read(authControllerProvider.notifier).logout();
  }
}

class _CurrentTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.tokens.softAccent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '本机',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
