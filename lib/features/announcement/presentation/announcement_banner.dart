import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_tokens.dart';
import '../data/announcement_repository.dart';

class AnnouncementBanner extends ConsumerWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(announcementsProvider);
    return async.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final a = items.first;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final tokens = context.tokens;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: tokens.softAccent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      if (a.contentMarkdown.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: MarkdownBody(
                            data: a.contentMarkdown,
                            styleSheet: MarkdownStyleSheet.fromTheme(theme)
                                .copyWith(
                                  p: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
                _MiniAction(
                  tooltip: '今日不再显示',
                  icon: Icons.visibility_off_outlined,
                  onTap: () async {
                    final repo = await ref.read(
                      announcementRepositoryProvider.future,
                    );
                    await repo.dismissToday(a.id);
                    ref.invalidate(announcementsProvider);
                  },
                ),
                _MiniAction(
                  tooltip: '关闭',
                  icon: Icons.close_rounded,
                  onTap: () async {
                    final repo = await ref.read(
                      announcementRepositoryProvider.future,
                    );
                    await repo.close(a.id);
                    ref.invalidate(announcementsProvider);
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: onTap,
    );
  }
}
