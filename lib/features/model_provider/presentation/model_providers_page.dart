import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/model_provider.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../models/data/models_repository.dart';
import '../data/model_provider_repository.dart';

/// Personal model providers — bring your own API key (DEEIX-Chat 0.4.4+).
class ModelProvidersPage extends ConsumerStatefulWidget {
  const ModelProvidersPage({super.key});

  @override
  ConsumerState<ModelProvidersPage> createState() => _ModelProvidersPageState();
}

class _ModelProvidersPageState extends ConsumerState<ModelProvidersPage> {
  late Future<(ModelProviderAccess, List<ModelProvider>)> _future = _load();

  Future<(ModelProviderAccess, List<ModelProvider>)> _load() async {
    final repo = await ref.read(modelProviderRepositoryProvider.future);
    final access = await repo.access();
    if (!access.enabled) return (access, const <ModelProvider>[]);
    return (access, await repo.list());
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    // Personal models show up in the model picker.
    ref.invalidate(modelsListProvider);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guard(Future<void> Function() task) async {
    try {
      await task();
      await _reload();
    } catch (e) {
      _toast('$e');
    }
  }

  Future<void> _add(ModelProviderAccess access) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _AddProviderPage(access: access)),
    );
    if (created == true) await _reload();
  }

  Future<void> _editModels(ModelProvider p) async {
    final repo = await ref.read(modelProviderRepositoryProvider.future);
    List<String> available;
    try {
      available = await repo.availableModels(p.id);
    } catch (e) {
      _toast('$e');
      return;
    }
    if (!mounted) return;
    final chosen = await pickModels(context, available, initial: p.models);
    if (chosen == null) return;
    await _guard(() async {
      await repo.update(p.id, models: chosen);
    });
  }

  Future<void> _replaceKey(ModelProvider p) async {
    final ctrl = TextEditingController();
    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('更换 API Key'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: '新的 API Key'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (key == null || key.trim().isEmpty) return;
    final repo = await ref.read(modelProviderRepositoryProvider.future);
    await _guard(() async {
      await repo.update(p.id, apiKey: key);
    });
  }

  Future<void> _delete(ModelProvider p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除模型服务'),
        content: Text('确定删除「${p.name}」？它提供的模型将不再可用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final repo = await ref.read(modelProviderRepositoryProvider.future);
    await _guard(() => repo.delete(p.id));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(ModelProviderAccess, List<ModelProvider>)>(
      future: _future,
      builder: (context, snap) {
        final access = snap.data?.$1;
        final canAdd =
            access != null &&
            access.enabled &&
            (access.maxPerUser <= 0 ||
                snap.data!.$2.length < access.maxPerUser);
        return Scaffold(
          appBar: AppBar(
            title: const Text('我的模型服务'),
            actions: [
              IconButton(
                tooltip: '刷新',
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          floatingActionButton: canAdd
              ? FloatingActionButton.extended(
                  onPressed: () => _add(access),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('添加'),
                )
              : null,
          body: () {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingView(message: '加载中…');
            }
            if (snap.hasError) {
              return ErrorView(message: '${snap.error}', onRetry: _reload);
            }
            if (access == null || !access.enabled) {
              return const EmptyState(
                icon: Icons.lock_outline_rounded,
                title: '未开放',
                message: '管理员没有开启个人模型服务。',
              );
            }
            final items = snap.data!.$2;
            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.hub_outlined,
                title: '还没有模型服务',
                message: '添加自己的 API Key（如 OpenAI 兼容接口），它的模型就会出现在模型列表里。',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = items[i];
                return ListTile(
                  leading: const Icon(Icons.hub_outlined),
                  title: Text(p.name.isEmpty ? p.host : p.name),
                  subtitle: Text(
                    [
                      p.protocol,
                      p.host,
                      if (p.keyHint.isNotEmpty) p.keyHint,
                      '${p.models.length} 个模型',
                      p.statusLabel,
                      if (p.lastError.isNotEmpty) '错误：${p.lastError}',
                    ].join(' · '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      switch (v) {
                        case 'toggle':
                          _guard(() async {
                            final repo = await ref.read(
                              modelProviderRepositoryProvider.future,
                            );
                            await repo.update(p.id, enabled: !p.enabled);
                          });
                        case 'models':
                          _editModels(p);
                        case 'key':
                          _replaceKey(p);
                        case 'delete':
                          _delete(p);
                      }
                    },
                    itemBuilder: (_) => [
                      if (p.status != 'suspended')
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(p.enabled ? '停用' : '启用'),
                        ),
                      const PopupMenuItem(value: 'models', child: Text('选择模型')),
                      const PopupMenuItem(value: 'key', child: Text('更换 Key')),
                      const PopupMenuItem(value: 'delete', child: Text('删除')),
                    ],
                  ),
                );
              },
            );
          }(),
        );
      },
    );
  }
}

/// Multi-select dialog for upstream model names.
Future<List<String>?> pickModels(
  BuildContext context,
  List<String> available, {
  List<String> initial = const [],
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) {
      final sel = {...initial.where(available.contains)};
      return StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('选择模型（${available.length}）'),
          content: SizedBox(
            width: double.maxFinite,
            child: available.isEmpty
                ? const Text('上游没有返回模型')
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final m in available)
                        CheckboxListTile(
                          dense: true,
                          value: sel.contains(m),
                          title: Text(m),
                          onChanged: (v) => setLocal(
                            () => v == true ? sel.add(m) : sel.remove(m),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => setLocal(() => sel.addAll(available)),
              child: const Text('全选'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, sel.toList()),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    },
  );
}

class _AddProviderPage extends ConsumerStatefulWidget {
  const _AddProviderPage({required this.access});

  final ModelProviderAccess access;

  @override
  ConsumerState<_AddProviderPage> createState() => _AddProviderPageState();
}

class _AddProviderPageState extends ConsumerState<_AddProviderPage> {
  final _name = TextEditingController();
  final _baseUrl = TextEditingController();
  final _apiKey = TextEditingController();
  late String _protocol = widget.access.protocols.isNotEmpty
      ? widget.access.protocols.first
      : 'openai';
  List<String>? _probed;
  List<String> _selected = const [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _probe() async {
    if (_baseUrl.text.trim().isEmpty || _apiKey.text.trim().isEmpty) {
      setState(() => _error = '请填写接口地址和 API Key');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = await ref.read(modelProviderRepositoryProvider.future);
      final models = await repo.probe(
        protocol: _protocol,
        baseURL: _baseUrl.text,
        apiKey: _apiKey.text,
      );
      if (!mounted) return;
      setState(() {
        _probed = models;
        _selected = models;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = await ref.read(modelProviderRepositoryProvider.future);
      await repo.create(
        protocol: _protocol,
        baseURL: _baseUrl.text,
        apiKey: _apiKey.text,
        name: _name.text,
        models: _selected,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final protocols = widget.access.protocols.isEmpty
        ? const ['openai']
        : widget.access.protocols;
    return Scaffold(
      appBar: AppBar(title: const Text('添加模型服务')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _protocol,
            decoration: const InputDecoration(labelText: '接口协议'),
            items: [
              for (final p in protocols)
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: _busy
                ? null
                : (v) => setState(() {
                    _protocol = v ?? _protocol;
                    _probed = null;
                  }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            maxLength: 64,
            decoration: const InputDecoration(labelText: '名称（可选）'),
          ),
          TextField(
            controller: _baseUrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: '接口地址',
              hintText: 'https://api.openai.com/v1',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKey,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'API Key'),
          ),
          const SizedBox(height: 8),
          Text(
            'API Key 只会发给你自己的 DEEIX 服务器保存，之后只显示掩码。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _probe,
            icon: const Icon(Icons.wifi_tethering_rounded),
            label: const Text('检测并获取模型'),
          ),
          if (_probed != null) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('已选 ${_selected.length} / ${_probed!.length} 个模型'),
              trailing: TextButton(
                onPressed: () async {
                  final r = await pickModels(
                    context,
                    _probed!,
                    initial: _selected,
                  );
                  if (r != null) setState(() => _selected = r);
                },
                child: const Text('调整'),
              ),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          GradientButton(
            loading: _busy,
            onPressed: _busy || _probed == null ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
