import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/billing.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../data/billing_repository.dart';

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

typedef _BillingData = ({
  BillingOverview overview,
  UsageSummary usage,
  List<DailyActivity> activity,
});

class _BillingPageState extends ConsumerState<BillingPage> {
  // Created once (not in build) so rebuilds don't refetch everything.
  late Future<_BillingData> _future = _load();

  Future<_BillingData> _load() async {
    final repo = await ref.read(billingRepositoryProvider.future);
    final overview = await repo.overview();
    final usage = await repo.usage();
    // Activity stats are new in DEEIX-Chat 0.4.4; older servers just skip it.
    final activity = await repo
        .activity(days: 14)
        .catchError((_) => const <DailyActivity>[]);
    return (overview: overview, usage: usage, activity: activity);
  }

  static String _money(double? v) => v == null ? '-' : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用量与订阅')),
      body: FutureBuilder<_BillingData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: '加载计费信息…');
          }
          if (snap.hasError) {
            return ErrorView(
              message: '${snap.error}',
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final theme = Theme.of(context);
          final overview = snap.data!.overview;
          final usage = snap.data!.usage;
          final used = overview.periodUsedUSD;
          final credit = overview.periodCreditUSD;
          final ratio = (used != null && credit != null && credit > 0)
              ? (used / credit).clamp(0.0, 1.0).toDouble()
              : null;

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // ---- usage hero ----
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.tokens.softAccent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '本周期用量 (USD)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(_money(used), style: theme.textTheme.displaySmall),
                        if (credit != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '/ ${_money(credit)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (ratio != null) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                    if (overview.periodRemainingUSD != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '剩余 ${_money(overview.periodRemainingUSD)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (snap.data!.activity.isNotEmpty) ...[
                const SectionLabel('近 14 天活跃'),
                _ActivityChart(days: snap.data!.activity),
              ],

              const SectionLabel('账户'),
              AppCardGroup(
                children: [
                  _kv(
                    context,
                    '计费模式',
                    overview.mode.isEmpty ? '-' : overview.mode,
                  ),
                  _kv(context, '套餐', overview.planName ?? '无'),
                  if (overview.account?.balanceUSD != null)
                    _kv(
                      context,
                      '账户余额',
                      '${_money(overview.account!.balanceUSD)} ${overview.account!.currency}',
                    ),
                ],
              ),

              if (overview.subscriptionLabels.isNotEmpty) ...[
                const SectionLabel('订阅权益'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: overview.subscriptionLabels
                        .map((e) => Chip(label: Text(e)))
                        .toList(),
                  ),
                ),
              ],

              SectionLabel('用量记录 · ${usage.total}'),
              if (usage.results.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: '暂无用量明细',
                  message: '产生调用后，费用记录会显示在这里。',
                )
              else
                AppCardGroup(
                  children: usage.results.take(30).map((row) {
                    final model =
                        '${row['platformModelName'] ?? row['model'] ?? row['upstreamModelName'] ?? ''}';
                    final cost =
                        '${row['billedUSD'] ?? row['cost'] ?? row['amount'] ?? ''}';
                    final created =
                        '${row['createdAt'] ?? row['created_at'] ?? ''}';
                    return ListTile(
                      dense: true,
                      title: Text(
                        model.isEmpty ? '调用' : model,
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: created.isEmpty ? null : Text(created),
                      trailing: Text(
                        cost,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(k, style: theme.textTheme.bodyMedium),
      trailing: Text(v, style: theme.textTheme.titleSmall),
    );
  }
}

/// Tiny bar chart of daily request counts (no chart dependency).
class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.days});

  final List<DailyActivity> days;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxCount = days.fold<int>(
      1,
      (m, d) => d.requestCount > m ? d.requestCount : m,
    );
    final totalReq = days.fold<int>(0, (s, d) => s + d.requestCount);
    final totalTok = days.fold<int>(0, (s, d) => s + d.tokenUsage);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in days)
                  Expanded(
                    child: Tooltip(
                      message:
                          '${d.date}：${d.requestCount} 次 · ${d.tokenUsage} tokens',
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4 + 68 * d.requestCount / maxCount,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '共 $totalReq 次请求 · $totalTok tokens',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
