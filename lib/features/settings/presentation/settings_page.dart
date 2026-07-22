import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/settings/app_preferences.dart';
import '../../../shared/l10n/app_l10n.dart';
import '../../../shared/models/llm_model.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/widgets/server_url_dialog.dart';
import '../../models/data/models_repository.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppL10n.of(context);
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final themeMode = ref.watch(themeModeProvider);
    final defaultModel = ref.watch(defaultModelProvider);
    final locale = ref.watch(localeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final models = ref.watch(modelsListProvider).asData?.value ?? const [];
    final serverUrl = ref.watch(serverBaseUrlProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (user != null) ...[
            const SizedBox(height: 8),
            AppCardGroup(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  leading: _RoundAvatar(icon: Icons.person_rounded),
                  title: Text(
                    user.displayLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    user.email ?? user.publicID ?? '${user.id ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
          ],

          // -------------------------------------------------------- appearance
          SectionLabel(l10n.appearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                    icon: const Icon(Icons.brightness_auto_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                    icon: const Icon(Icons.light_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                    icon: const Icon(Icons.dark_mode_rounded),
                  ),
                ],
                selected: {themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (set) {
                  ref.read(themeModeProvider.notifier).setMode(set.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCardGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(l10n.language),
                subtitle: Text(
                  locale == null
                      ? l10n.followSystem
                      : (locale.languageCode == 'zh'
                            ? l10n.chinese
                            : l10n.english),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickLanguage(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.format_size_rounded),
                title: Text(
                  '${l10n.fontSize}  ·  ${fontScale.toStringAsFixed(2)}×',
                ),
                subtitle: Slider(
                  value: fontScale,
                  min: 0.85,
                  max: 1.4,
                  divisions: 11,
                  label: '${fontScale.toStringAsFixed(2)}×',
                  onChanged: (v) =>
                      ref.read(fontScaleProvider.notifier).setScale(v),
                ),
              ),
            ],
          ),

          // ------------------------------------------------------------- chat
          SectionLabel(l10n.chatPreferences),
          AppCardGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.keyboard_return_rounded),
                title: Text(l10n.sendWithEnter),
                subtitle: Text(l10n.sendWithEnterHint),
                value: ref.watch(sendWithEnterProvider),
                onChanged: (v) =>
                    ref.read(sendWithEnterProvider.notifier).setEnabled(v),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded),
                title: Text(l10n.bubbleStyle),
                subtitle: Text(
                  ref.watch(bubbleStyleProvider) == 'compact'
                      ? l10n.bubbleCompact
                      : l10n.bubbleComfortable,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickBubbleStyle(context, ref, l10n),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: Text(l10n.defaultModel),
                subtitle: Text(defaultModel ?? l10n.notSet),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: models.isEmpty
                    ? null
                    : () async {
                        final selected = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => _DefaultModelSheet(
                            models: models,
                            selected: defaultModel,
                            title: l10n.selectDefaultModel,
                          ),
                        );
                        if (selected != null) {
                          await ref
                              .read(defaultModelProvider.notifier)
                              .setModel(selected);
                        }
                      },
              ),
            ],
          ),

          // ---------------------------------------------------------- account
          SectionLabel('账户'),
          AppCardGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(l10n.billing),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/billing'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(l10n.myFiles),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/files'),
              ),
              ListTile(
                leading: const Icon(Icons.devices_other_rounded),
                title: const Text('活跃设备'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/sessions'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_special_outlined),
                title: const Text('项目分组'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/projects'),
              ),
            ],
          ),

          // ------------------------------------------------------ about & data
          SectionLabel('关于与数据'),
          AppCardGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: Text(l10n.clearCache),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  await DefaultCacheManager().emptyCache();
                  final prefs = await ref.read(appPreferencesProvider.future);
                  await prefs.setGenerationTemperature(null);
                  await prefs.setGenerationMaxTokens(null);
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.cacheCleared)));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: Text(l10n.apiAddress),
                subtitle: Text(
                  serverUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showServerUrlDialog(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.privacy),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => _openUrl('$serverUrl/privacy'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.terms),
                trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                onTap: () => _openUrl('$serverUrl/terms'),
              ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) {
                  final v = snap.data;
                  return ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: Text(l10n.about),
                    subtitle: Text(
                      v == null
                          ? 'DEEIX'
                          : '${v.appName} ${v.version}+${v.buildNumber}  ·  API 0.3.3',
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: auth.isLoading
                  ? null
                  : () => _confirmLogout(context, ref, l10n),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(l10n.logout),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (ctx) {
        final sheetL10n = AppL10n.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_auto_rounded),
                title: Text(sheetL10n.followSystem),
                onTap: () => Navigator.pop(ctx, ''),
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(sheetL10n.chinese),
                onTap: () => Navigator.pop(ctx, 'zh'),
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(sheetL10n.english),
                onTap: () => Navigator.pop(ctx, 'en'),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    await ref
        .read(localeProvider.notifier)
        .setLocale(selected.isEmpty ? null : Locale(selected));
  }

  Future<void> _pickBubbleStyle(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
  ) async {
    final current = ref.read(bubbleStyleProvider);
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded),
              title: Text(l10n.bubbleComfortable),
              trailing: current == 'comfortable'
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(ctx, 'comfortable'),
            ),
            ListTile(
              leading: const Icon(Icons.density_small_rounded),
              title: Text(l10n.bubbleCompact),
              trailing: current == 'compact'
                  ? const Icon(Icons.check_rounded)
                  : null,
              onTap: () => Navigator.pop(ctx, 'compact'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await ref.read(bubbleStyleProvider.notifier).setStyle(selected);
    }
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    AppL10n l10n,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.confirmLogout),
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
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _RoundAvatar extends StatelessWidget {
  const _RoundAvatar({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: tokens.softAccent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: scheme.primary, size: 22),
    );
  }
}

class _DefaultModelSheet extends StatefulWidget {
  const _DefaultModelSheet({
    required this.models,
    required this.title,
    this.selected,
  });

  final List<LlmModel> models;
  final String? selected;
  final String title;

  @override
  State<_DefaultModelSheet> createState() => _DefaultModelSheetState();
}

class _DefaultModelSheetState extends State<_DefaultModelSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final q = _q.trim().toLowerCase();
    final filtered = widget.models.where((m) {
      if (q.isEmpty) return true;
      final name = m.platformModelName.toLowerCase();
      final vendor = m.vendor.toLowerCase();
      final caps = m.capabilityTags.join(' ').toLowerCase();
      final price = (m.pricingSummary ?? '').toLowerCase();
      return name.contains(q) ||
          vendor.contains(q) ||
          caps.contains(q) ||
          price.contains(q);
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(widget.title, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: '搜索模型…',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final m = filtered[i];
                  final name = m.platformModelName;
                  final selected = widget.selected == name;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? context.tokens.softAccent
                          : scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? scheme.primary.withValues(alpha: 0.4)
                            : context.tokens.hairline,
                      ),
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      title: Text(name, style: theme.textTheme.titleSmall),
                      subtitle: Text(
                        [
                          m.vendor,
                          if (m.capabilityTags.isNotEmpty)
                            m.capabilityTags.take(3).join(', '),
                          if (m.pricingSummary != null) m.pricingSummary!,
                        ].where((e) => e.isNotEmpty).join('  ·  '),
                      ),
                      trailing: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: scheme.primary,
                            )
                          : null,
                      onTap: () => Navigator.pop(context, name),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
