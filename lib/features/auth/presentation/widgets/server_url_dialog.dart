import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/settings/app_preferences.dart';
import '../auth_controller.dart';

/// View / change the API server address. On save it persists the new origin
/// (Dio + auth rebuild automatically), clears the old session and signs out so
/// the user re-authenticates against the new server.
Future<void> showServerUrlDialog(BuildContext context, WidgetRef ref) async {
  final current = ref.read(serverBaseUrlProvider);
  final ctrl = TextEditingController(text: current);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('服务器地址'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('填写你的 DEEIX 服务地址（只需域名，无需 /api/v1）。切换后需要重新登录。'),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'https://your.domain',
              prefixIcon: Icon(Icons.dns_outlined),
            ),
            onSubmitted: (_) => Navigator.pop(ctx, true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('保存'),
        ),
      ],
    ),
  );
  final text = ctrl.text;
  ctrl.dispose();
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final applied = await ref.read(serverBaseUrlProvider.notifier).setUrl(text);
  if (applied.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('地址无效，请检查后重试')));
    return;
  }
  if (applied == current) return; // unchanged — don't disturb the session

  // New origin → drop the old session and force sign-in against it.
  await ref.read(tokenStorageProvider).clear();
  ref.read(authControllerProvider.notifier).signOutLocal();
  messenger.showSnackBar(SnackBar(content: Text('已切换服务器：$applied，请重新登录')));
}
