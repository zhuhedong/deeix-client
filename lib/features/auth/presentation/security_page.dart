import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../data/two_factor_repository.dart';

/// Account security: TOTP two-factor setup / disable / recovery codes
/// (DEEIX-Chat 0.4.4+).
class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  late Future<TwoFactorStatus> _future = _load();
  bool _busy = false;

  Future<TwoFactorStatus> _load() async {
    final repo = await ref.read(twoFactorRepositoryProvider.future);
    return repo.status();
  }

  Future<void> _reload() async => setState(() => _future = _load());

  Future<TwoFactorRepository> get _repo =>
      ref.read(twoFactorRepositoryProvider.future);

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _askCode(String title, {String? message}) async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[Text(message), const SizedBox(height: 12)],
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 32,
              decoration: const InputDecoration(labelText: '验证器中的 6 位验证码'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return (code == null || code.length < 6) ? null : code;
  }

  Future<void> _showRecoveryCodes(List<String> codes) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请妥善保存。手机丢失时可用恢复码登录，每个只能用一次，只显示这一次。'),
            const SizedBox(height: 12),
            SelectableText(
              codes.join('\n'),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: codes.join('\n'))),
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('我已保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _guard(Future<void> Function() task) async {
    setState(() => _busy = true);
    try {
      await task();
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  Future<void> _enable() => _guard(() async {
    final repo = await _repo;
    final setup = await repo.startSetup();
    if (!mounted) return;
    final code = await _askCode(
      '开启两步验证',
      message:
          '在验证器 App（如 Google Authenticator）中添加以下密钥，'
          '然后输入它显示的验证码：\n\n${setup.secret}',
    );
    if (code == null) {
      await repo.cancelSetup();
      return;
    }
    final codes = await repo.confirmSetup(code);
    if (!mounted) return;
    _toast('两步验证已开启');
    if (codes.isNotEmpty) await _showRecoveryCodes(codes);
  });

  Future<void> _disable() => _guard(() async {
    final code = await _askCode('关闭两步验证');
    if (code == null) return;
    await (await _repo).disable(code);
    _toast('两步验证已关闭');
  });

  Future<void> _regenerate() => _guard(() async {
    final code = await _askCode('重新生成恢复码', message: '旧的恢复码将全部失效。');
    if (code == null) return;
    final codes = await (await _repo).regenerateRecoveryCodes(code);
    if (mounted && codes.isNotEmpty) await _showRecoveryCodes(codes);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户安全'),
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: FutureBuilder<TwoFactorStatus>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done && !snap.hasData) {
            return const LoadingView(message: '加载中…');
          }
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}', onRetry: _reload);
          }
          final s = snap.data!;
          if (!s.available) {
            return const EmptyState(
              icon: Icons.shield_outlined,
              title: '两步验证未开放',
              message: '管理员没有为此服务器开启两步验证。',
            );
          }
          return ListView(
            children: [
              SectionLabel('两步验证（TOTP）'),
              AppCardGroup(
                children: [
                  ListTile(
                    leading: Icon(
                      s.totpEnabled
                          ? Icons.verified_user_rounded
                          : Icons.shield_outlined,
                    ),
                    title: Text(s.totpEnabled ? '已开启' : '未开启'),
                    subtitle: Text(
                      s.totpEnabled
                          ? '剩余 ${s.recoveryCount} 个恢复码'
                          : (s.required ? '管理员要求开启两步验证' : '登录时额外输入验证器中的验证码'),
                    ),
                  ),
                  if (!s.totpEnabled)
                    ListTile(
                      leading: const Icon(Icons.add_moderator_outlined),
                      title: const Text('开启两步验证'),
                      enabled: !_busy,
                      onTap: _enable,
                    )
                  else ...[
                    ListTile(
                      leading: const Icon(Icons.key_rounded),
                      title: const Text('重新生成恢复码'),
                      enabled: !_busy,
                      onTap: _regenerate,
                    ),
                    if (!s.required)
                      ListTile(
                        leading: const Icon(Icons.remove_moderator_outlined),
                        title: const Text('关闭两步验证'),
                        enabled: !_busy,
                        onTap: _disable,
                      ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
