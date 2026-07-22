import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/ui_kit.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _avatar;
  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();
  final _code = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _name = TextEditingController(text: user?.displayName ?? '');
    _avatar = TextEditingController(text: user?.avatarURL ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _avatar.dispose();
    _oldPass.dispose();
    _newPass.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          displayName: _name.text.trim().isEmpty ? null : _name.text.trim(),
          avatarURL: _avatar.text.trim().isEmpty ? null : _avatar.text.trim(),
        );
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? '资料已更新' : '更新失败')));
  }

  Future<void> _changePassword() async {
    if (_newPass.text.length < 8) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('新密码至少 8 位')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = await ref.read(authRepositoryProvider.future);
      // Best-effort: try start then complete with common body shapes.
      try {
        await repo.passwordChangeStart();
      } catch (_) {}
      await repo.passwordChangeComplete({
        'currentPassword': _oldPass.text,
        'oldPassword': _oldPass.text,
        'newPassword': _newPass.text,
        'password': _newPass.text,
        if (_code.text.trim().isNotEmpty) 'code': _code.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('密码已修改')));
        _oldPass.clear();
        _newPass.clear();
        _code.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('修改密码失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('个人资料')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SizedBox(height: 16),
          Center(child: BrandMark(size: 60, radius: 20)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.displayLabel ?? '账户',
              style: theme.textTheme.titleLarge,
            ),
          ),
          Center(
            child: Text(
              user?.email ?? user?.username ?? user?.publicID ?? '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SectionLabel('资料'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: '昵称（3–16 字）',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _avatar,
                  decoration: const InputDecoration(
                    labelText: '头像 URL（可选）',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  onPressed: _saving ? null : _saveProfile,
                  loading: _saving,
                  child: const Text('保存资料'),
                ),
              ],
            ),
          ),

          const SectionLabel('修改密码'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _oldPass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '当前密码',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '新密码（至少 8 位）',
                    prefixIcon: Icon(Icons.lock_reset_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: '验证码（若账号开启 2FA / 邮箱验证）',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _saving ? null : _changePassword,
                    child: const Text('修改密码'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
