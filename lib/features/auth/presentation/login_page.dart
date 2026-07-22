import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/settings/app_preferences.dart';
import '../../../shared/l10n/app_l10n.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'widgets/server_url_dialog.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .login(_accountCtrl.text.trim(), _passwordCtrl.text);
    final auth = ref.read(authControllerProvider);
    if (auth.status == AuthStatus.twoFactor) {
      if (mounted) context.go('/two-factor');
      return;
    }
    if (!ok && mounted) {
      final err = auth.error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err ?? '登录失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final auth = ref.watch(authControllerProvider);
    final options = ref.watch(loginOptionsProvider);
    final theme = Theme.of(context);
    final registrationEnabled =
        options.asData?.value.emailRegistrationEnabled ?? false;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const Center(child: BrandMark(size: 68)),
                    const SizedBox(height: 24),
                    Text(
                      AppConfig.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.nativeClient,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 36),
                    TextFormField(
                      controller: _accountCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.account,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.account;
                        }
                        if (v.trim().length < 3) return l10n.account;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return l10n.password;
                        if (v.length < 6) return l10n.password;
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      onPressed: auth.isLoading ? null : _submit,
                      loading: auth.isLoading,
                      child: Text(l10n.login),
                    ),
                    if (registrationEnabled) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: Text(l10n.register),
                      ),
                    ],
                    if (options.asData?.value.passwordResetEnabled == true)
                      TextButton(
                        onPressed: () => context.push('/password-reset'),
                        child: Text(l10n.forgotPassword),
                      ),
                    if ((options.asData?.value.providers ?? const [])
                        .isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'SSO',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...options.asData!.value.providers.map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton.icon(
                            onPressed: auth.isLoading
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final router = GoRouter.of(context);
                                    final ok = await ref
                                        .read(authControllerProvider.notifier)
                                        .loginWithProvider(p);
                                    if (!mounted) return;
                                    final st = ref.read(authControllerProvider);
                                    if (st.status == AuthStatus.twoFactor) {
                                      router.go('/two-factor');
                                      return;
                                    }
                                    if (!ok) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(st.error ?? 'SSO 登录失败'),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.login),
                            label: Text(p.name.isEmpty ? p.slug : p.name),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => showServerUrlDialog(context, ref),
                        icon: const Icon(Icons.dns_outlined, size: 16),
                        label: Text(
                          ref.watch(serverBaseUrlProvider),
                          style: theme.textTheme.labelSmall,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
