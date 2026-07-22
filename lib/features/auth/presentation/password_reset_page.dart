import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/ui_kit.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_error_text.dart';

class PasswordResetPage extends ConsumerStatefulWidget {
  const PasswordResetPage({super.key});

  @override
  ConsumerState<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends ConsumerState<PasswordResetPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.passwordResetStart(email: _email.text.trim());
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _complete() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      await repo.passwordResetComplete(
        email: _email.text.trim(),
        code: _code.text.trim(),
        newPassword: _password.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('密码已重置，请登录')));
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = ref.watch(loginOptionsProvider);
    final enabled = options.asData?.value.passwordResetEnabled ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('重置密码')),
      body: !enabled
          ? const EmptyState(
              icon: Icons.lock_reset_rounded,
              title: '未开启密码重置',
              message: '当前站点未开启密码重置，请联系管理员。',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 8),
                    Center(child: BrandMark(size: 56, radius: 18)),
                    const SizedBox(height: 16),
                    Text(
                      _sent ? '设置新密码' : '找回密码',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sent ? '输入收到的验证码并设置新密码。' : '输入账号邮箱，我们会发送验证码。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    if (_sent) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _code,
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '新密码（至少 8 位）',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ],
                    AuthErrorText(_error),
                    const SizedBox(height: 24),
                    GradientButton(
                      onPressed: _loading ? null : (_sent ? _complete : _start),
                      loading: _loading,
                      child: Text(_sent ? '完成重置' : '发送验证码'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
