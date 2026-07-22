import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/ui_kit.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'widgets/auth_error_text.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<AuthRepository> get _repo => ref.read(authRepositoryProvider.future);

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = '请输入有效邮箱');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await _repo;
      await repo.registerEmailStart(email: email);
      setState(() {
        _codeSent = true;
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('验证码已发送（如服务端已开启验证）')));
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await _repo;
      final user = await repo.registerEmailComplete(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
      );
      // Force auth state to authenticated.
      await ref
          .read(authControllerProvider.notifier)
          .login(_emailCtrl.text.trim(), _passwordCtrl.text);
      // If login failed but register returned user with token, bootstrap.
      if (!ref.read(authControllerProvider).isAuthenticated) {
        await ref.read(authControllerProvider.notifier).bootstrap();
      }
      if (mounted && ref.read(authControllerProvider).isAuthenticated) {
        context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注册成功，请登录（${user.displayLabel}）')),
        );
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
    final enabled = options.asData?.value.emailRegistrationEnabled ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('邮箱注册')),
      body: !enabled
          ? const EmptyState(
              icon: Icons.mark_email_unread_outlined,
              title: '未开启邮箱注册',
              message: '当前站点未开启邮箱注册，请联系管理员或使用其他方式登录。',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(child: BrandMark(size: 56, radius: 18)),
                        const SizedBox(height: 16),
                        Text(
                          '创建账号',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: '邮箱',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || !v.contains('@')) return '请输入邮箱';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _codeCtrl,
                                decoration: const InputDecoration(
                                  labelText: '验证码（如需要）',
                                  prefixIcon: Icon(Icons.pin_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: FilledButton.tonal(
                                onPressed: _loading ? null : _sendCode,
                                child: Text(_codeSent ? '重发' : '发送验证码'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: '密码（至少 8 位）',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 8) return '密码至少 8 位';
                            return null;
                          },
                        ),
                        AuthErrorText(_error),
                        const SizedBox(height: 24),
                        GradientButton(
                          onPressed: _loading ? null : _complete,
                          loading: _loading,
                          child: const Text('完成注册'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
