import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/billing.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../data/billing_repository.dart';

class BillingPage extends ConsumerWidget {
  const BillingPage({super.key});

  static String _money(double? v) => v == null ? '-' : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('用量与订阅')),
      body: FutureBuilder<({BillingOverview overview, UsageSummary usage})>(
        future: () async {
          final repo = await ref.read(billingRepositoryProvider.future);
          final overview = await repo.overview();
          final usage = await repo.usage();
          return (overview: overview, usage: usage);
        }(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(message: '加载计费信息…');
          }
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}');
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
