import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/update_service.dart';

/// Runs a check and shows the dialog if needed. With [manual], also reports
/// "already up to date" and errors.
Future<void> runUpdateCheck(
  BuildContext context,
  WidgetRef ref, {
  bool manual = false,
}) async {
  final UpdateService service;
  try {
    service = await ref.read(updateServiceProvider.future);
  } catch (_) {
    return;
  }
  final result = await service.check(manual: manual);
  if (result == null || !context.mounted) return;
  if (result.update != null) {
    await showUpdateDialog(context, service, result.update!, result);
  } else if (manual) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.error ?? '已是最新版本（${result.currentVersion}）'),
      ),
    );
  }
}

Future<void> showUpdateDialog(
  BuildContext context,
  UpdateService service,
  ReleaseInfo release,
  UpdateCheck check,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _UpdateDialog(service: service, release: release, check: check),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({
    required this.service,
    required this.release,
    required this.check,
  });

  final UpdateService service;
  final ReleaseInfo release;
  final UpdateCheck check;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  CancelToken? _cancel;
  double? _progress;
  String? _status;
  File? _downloaded;

  bool get _busy => _cancel != null;

  @override
  void dispose() {
    _cancel?.cancel('dialog closed');
    super.dispose();
  }

  Future<void> _openReleasePage() async {
    final url = widget.release.htmlUrl.isNotEmpty
        ? widget.release.htmlUrl
        : UpdateConfig.releasesPage;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _update() async {
    if (!Platform.isAndroid) {
      await _openReleasePage();
      if (mounted) Navigator.pop(context);
      return;
    }
    if (_downloaded != null) return _install(_downloaded!);
    setState(() {
      _cancel = CancelToken();
      _progress = 0;
      _status = '正在下载…';
    });
    try {
      final file = await widget.service.downloadApk(
        widget.release,
        cancelToken: _cancel,
        onProgress: (r, t) {
          if (!mounted) return;
          setState(() => _progress = t > 0 ? r / t : null);
        },
      );
      if (!mounted) return;
      setState(() {
        _downloaded = file;
        _cancel = null;
        _status = '下载完成，正在打开安装程序…';
      });
      await _install(file);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _cancel = null;
        _progress = null;
        _status = e.type == DioExceptionType.cancel
            ? '已取消下载'
            : '下载失败：${e.message ?? e.type.name}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cancel = null;
        _progress = null;
        _status = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _install(File file) async {
    final outcome = await widget.service.install(file);
    if (!mounted) return;
    switch (outcome) {
      case InstallOutcome.started:
        setState(() => _status = '请在系统安装界面中确认安装');
      case InstallOutcome.needsPermission:
        setState(() => _status = '需要允许本应用“安装未知应用”。请在设置中开启后返回，再点“安装”。');
        await openAppSettings();
      case InstallOutcome.failed:
        setState(() => _status = '无法打开安装程序，可在浏览器中下载安装');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.release;
    final theme = Theme.of(context);
    final android = Platform.isAndroid;
    return AlertDialog(
      title: Text('发现新版本 ${r.version}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前版本 ${widget.check.currentVersion}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  r.notes.trim().isEmpty ? '（无更新说明）' : r.notes.trim(),
                ),
              ),
            ),
            if (!android) ...[
              const SizedBox(height: 12),
              Text('iOS 不支持应用内更新，将打开发布页面。', style: theme.textTheme.bodySmall),
            ],
            if (_progress != null && _busy) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text(
                _progress == null
                    ? ''
                    : '${(_progress! * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (_status != null) ...[
              const SizedBox(height: 8),
              Text(_status!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
      actions: [
        if (!_busy)
          TextButton(
            onPressed: () async {
              await widget.service.ignore(r);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('忽略此版本'),
          ),
        TextButton(
          onPressed: () {
            _cancel?.cancel('later');
            Navigator.pop(context);
          },
          child: Text(_busy ? '取消' : '稍后'),
        ),
        if (!_busy)
          FilledButton(
            onPressed: _update,
            child: Text(
              !android
                  ? '前往下载'
                  : _downloaded != null
                  ? '安装'
                  : '更新',
            ),
          ),
      ],
    );
  }
}

/// Wraps the home screen and runs one throttled automatic check per app
/// launch, shortly after the first frame.
class StartupUpdateCheck extends ConsumerStatefulWidget {
  const StartupUpdateCheck({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StartupUpdateCheck> createState() => _StartupUpdateCheckState();
}

class _StartupUpdateCheckState extends ConsumerState<StartupUpdateCheck> {
  static bool _ranThisLaunch = false;

  @override
  void initState() {
    super.initState();
    if (_ranThisLaunch) return;
    _ranThisLaunch = true;
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted) runUpdateCheck(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
