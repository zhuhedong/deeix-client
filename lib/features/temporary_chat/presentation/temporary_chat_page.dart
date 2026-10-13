import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_preferences.dart';
import '../../../shared/models/message.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/presentation/widgets/message_bubble.dart';
import '../../models/data/models_repository.dart';

String _randomId(String prefix) {
  final r = Random.secure();
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${r.nextInt(1 << 32)}';
}

/// Temporary ("incognito") chat — DEEIX-Chat 0.4.4+.
///
/// Nothing is stored on the server; the client keeps the history in memory
/// and sends all of it (max 100 messages) with every turn. Leaving the page
/// discards the conversation.
class TemporaryChatPage extends ConsumerStatefulWidget {
  const TemporaryChatPage({super.key});

  @override
  ConsumerState<TemporaryChatPage> createState() => _TemporaryChatPageState();
}

class _TemporaryChatPageState extends ConsumerState<TemporaryChatPage> {
  static const _maxHistory = 100;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _sessionId = _randomId('tmp');
  final List<ChatMessage> _messages = [];
  CancelToken? _cancel;
  bool _streaming = false;
  String? _model;

  @override
  void dispose() {
    _cancel?.cancel('disposed');
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _setLast(ChatMessage Function(ChatMessage) f) {
    if (!mounted || _messages.isEmpty) return;
    setState(() => _messages[_messages.length - 1] = f(_messages.last));
    _scrollToEnd();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final model = _model;
    if (text.isEmpty || _streaming) return;
    if (model == null || model.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择模型')));
      return;
    }
    _input.clear();
    setState(() {
      _messages.add(ChatMessage.localUser(text));
      _messages.add(ChatMessage.streamingAssistant());
      _streaming = true;
    });
    _scrollToEnd();

    final history = _messages
        .where((m) => !m.isStreaming && m.content.isNotEmpty)
        .map(
          (m) => (
            role: m.role == MessageRole.user ? 'user' : 'assistant',
            content: m.content,
          ),
        )
        .toList();
    final trimmed = history.length > _maxHistory
        ? history.sublist(history.length - _maxHistory)
        : history;

    _cancel = CancelToken();
    final buffer = StringBuffer();
    final think = StringBuffer();
    try {
      final repo = await ref.read(chatRepositoryProvider.future);
      await for (final chunk in repo.streamTemporaryChat(
        sessionId: _sessionId,
        clientRunId: _randomId('run'),
        model: model,
        messages: trimmed,
        options: ref.read(genOptionsProvider).toOptionsMap(),
        cancelToken: _cancel,
      )) {
        if (chunk.delta != null) buffer.write(chunk.delta);
        if (chunk.thinkDelta != null) think.write(chunk.thinkDelta);
        if (chunk.error != null) {
          _setLast(
            (m) => m.copyWith(
              content: buffer.toString(),
              isStreaming: false,
              error: chunk.error,
            ),
          );
          return;
        }
        final fin = chunk.finalAssistantMessage;
        _setLast(
          (m) => m.copyWith(
            content: (fin != null && fin.content.isNotEmpty)
                ? fin.content
                : buffer.toString(),
            thinking: think.toString(),
            isStreaming: !chunk.done,
          ),
        );
        if (chunk.done) return;
      }
      _setLast((m) => m.copyWith(isStreaming: false));
    } catch (e) {
      final cancelled = e is DioException && e.type == DioExceptionType.cancel;
      _setLast(
        (m) => m.copyWith(
          content: buffer.toString(),
          isStreaming: false,
          error: cancelled ? '已停止' : '$e',
        ),
      );
    } finally {
      if (mounted) setState(() => _streaming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final models = ref.watch(modelsListProvider);
    _model ??= ref.watch(defaultModelProvider);
    final names =
        models.asData?.value.map((m) => m.platformModelName).toList() ??
        const <String>[];
    if ((_model == null || !names.contains(_model)) && names.isNotEmpty) {
      _model = names.first;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('临时对话'),
        actions: [
          if (names.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: '选择模型',
              initialValue: _model,
              onSelected: (v) => setState(() => _model = v),
              itemBuilder: (_) => [
                for (final n in names) PopupMenuItem(value: n, child: Text(n)),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        _model ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),
          IconButton(
            tooltip: '清空',
            onPressed: _streaming ? null : () => setState(_messages.clear),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Text(
              '临时对话不会保存到服务器，离开此页面后记录即消失。',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const EmptyState(
                    icon: Icons.visibility_off_outlined,
                    title: '开始一段临时对话',
                    message: '适合不想留下记录的问题。',
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return MessageBubble(
                        message: m,
                        onCopy: () =>
                            Clipboard.setData(ClipboardData(text: m.content)),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(hintText: '输入消息…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _streaming
                      ? IconButton.filledTonal(
                          tooltip: '停止',
                          onPressed: () => _cancel?.cancel('user-stop'),
                          icon: const Icon(Icons.stop_rounded),
                        )
                      : IconButton.filled(
                          tooltip: '发送',
                          onPressed: _send,
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
