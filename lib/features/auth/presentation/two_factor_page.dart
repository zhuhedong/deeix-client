import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/ui_kit.dart';
import 'auth_controller.dart';
import 'widgets/auth_error_text.dart';

class TwoFactorPage extends ConsumerStatefulWidget {
  const TwoFactorPage({super.key});

  @override
  ConsumerState<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends ConsumerState<TwoFactorPage> {
  final _codeCtrl = TextEditingController();
  String _method = 'two_factor';

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final methods = auth.twoFactorMethods.isEmpty
        ? const ['two_factor']
        : auth.twoFactorMethods;
    if (!methods.contains(_method)) {
      _method = methods.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('二次验证'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(authControllerProvider.notifier).cancelTwoFactor();
            context.go('/login');
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(child: BrandMark(size: 56, radius: 18)),
                const SizedBox(height: 16),
                Text(
                  '验证你的身份',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '请输入验证器中的 6 位验证码，或使用恢复码。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _method,
                  decoration: const InputDecoration(labelText: '验证方式'),
                  items: methods
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m == 'email' ? '邮箱验证码' : '两步验证 / 恢复码'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _method = v);
                  },
                ),
                if (_method == 'email') ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.mail_outline_rounded, size: 18),
                      onPressed: auth.isLoading ? null : _sendEmailCode,
                      label: const Text('发送邮箱验证码'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: '验证码',
                    hintText: '6 位数字或恢复码',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                AuthErrorText(auth.error),
                const SizedBox(height: 24),
                GradientButton(
                  onPressed: auth.isLoading ? null : _verify,
                  loading: auth.isLoading,
                  child: const Text('验证并登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendEmailCode() async {
    try {
      await ref.read(authControllerProvider.notifier).startTwoFactorEmail();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('验证码已发送')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _verify() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .verifyTwoFactor(code: _codeCtrl.text, verificationMethod: _method);
    if (ok && mounted) context.go('/');
  }
}
