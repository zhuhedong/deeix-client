import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/connectivity_provider.dart';
import '../../../core/settings/app_preferences.dart';
import '../../../shared/models/message.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/offline_banner.dart';
import 'dart:convert';

import '../../../shared/models/mcp_tool.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../../conversation/presentation/conversation_drawer.dart';
import '../../models/data/models_repository.dart';
import '../../prompt/data/prompt_repository.dart';
import '../../tools/data/tools_repository.dart';
import 'chat_controller.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_bubble.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Load older near top.
    if (_scrollController.position.pixels <= 80) {
      ref
          .read(chatControllerProvider(widget.conversationId).notifier)
          .loadOlderMessages();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _showMessageActions(ChatMessageActions message) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制'),
              onTap: () {
                Navigator.pop(ctx);
                _copy(message.content);
              },
            ),
            if (message.canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑并重发'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editMessage(message.messageId, message.content);
                },
              ),
            if (message.canRegenerate)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('重新生成'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(
                        chatControllerProvider(widget.conversationId).notifier,
                      )
                      .regenerate();
                },
              ),
            if (message.canRetry)
              ListTile(
                leading: const Icon(Icons.replay),
                title: const Text('重试'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(
                        chatControllerProvider(widget.conversationId).notifier,
                      )
                      .retryLastFailed();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMessage(String id, String content) async {
    final ctrl = TextEditingController(text: content);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(controller: ctrl, maxLines: 6, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('重发'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (next == null || next.isEmpty) return;
    await ref
        .read(chatControllerProvider(widget.conversationId).notifier)
        .editAndResend(id, next);
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 4096,
      );
      if (file == null) return;
      await ref
          .read(chatControllerProvider(widget.conversationId).notifier)
          .addLocalFile(file.path, fileName: file.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
        withData: false,
      );
      if (result == null) return;
      final notifier = ref.read(
        chatControllerProvider(widget.conversationId).notifier,
      );
      for (final f in result.files) {
        if (f.path == null) continue;
        await notifier.addLocalFile(f.path!, fileName: f.name);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择文件失败: $e')));
    }
  }

  Future<void> _pickPreset() async {
    try {
      final presets = await ref.read(promptPresetsProvider.future);
      if (!mounted) return;
      final selected = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.55,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '提示词预设',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: presets.isEmpty
                      ? const Center(child: Text('暂无可用预设'))
                      : ListView.separated(
                          itemCount: presets.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = presets[i];
                            return ListTile(
                              title: Text(p.title),
                              subtitle: Text(
                                p.description.isNotEmpty
                                    ? p.description
                                    : p.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => Navigator.pop(ctx, p.content),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
      if (selected == null || selected.isEmpty || !mounted) return;
      // Send preset content immediately as a user message.
      await ref
          .read(chatControllerProvider(widget.conversationId).notifier)
          .send(selected);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载提示词失败: $e')));
      }
    }
  }

  Future<void> _exportMenu() async {
    final notifier = ref.read(
      chatControllerProvider(widget.conversationId).notifier,
    );
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('导出 JSON（服务端）'),
              onTap: () => Navigator.pop(ctx, 'json'),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('导出 Markdown（本地）'),
              onTap: () => Navigator.pop(ctx, 'md'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    try {
      if (choice == 'json') {
        final data = await notifier.exportJson();
        final text = const JsonEncoder.withIndent('  ').convert(data);
        await Clipboard.setData(ClipboardData(text: text));
      } else {
        await Clipboard.setData(ClipboardData(text: notifier.exportMarkdown()));
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _pickTools(ChatState state) async {
    final toolsAsync = ref.read(mcpToolsProvider);
    final tools = toolsAsync.asData?.value;
    if (tools == null) {
      // trigger load
      ref.invalidate(mcpToolsProvider);
      final loaded = await ref.read(mcpToolsProvider.future);
      if (!mounted) return;
      await _showToolsSheet(loaded, state.selectedToolIds);
      return;
    }
    await _showToolsSheet(tools, state.selectedToolIds);
  }

  Future<void> _showToolsSheet(List<McpTool> tools, Set<int> selected) async {
    final draft = {...selected};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.6,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '选择 MCP 工具',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: tools.isEmpty
                          ? const Center(child: Text('暂无可用工具'))
                          : ListView.builder(
                              itemCount: tools.length,
                              itemBuilder: (context, i) {
                                final t = tools[i];
                                final checked = draft.contains(t.id);
                                return CheckboxListTile(
                                  value: checked,
                                  title: Text(t.label),
                                  subtitle: Text(
                                    [
                                      if (t.serverName.isNotEmpty) t.serverName,
                                      if (t.description.isNotEmpty)
                                        t.description,
                                    ].join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onChanged: (v) {
                                    setLocal(() {
                                      if (v == true) {
                                        draft.add(t.id);
                                      } else {
                                        draft.remove(t.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: FilledButton(
                        onPressed: () {
                          ref
                              .read(
                                chatControllerProvider(
                                  widget.conversationId,
                                ).notifier,
                              )
                              .setSelectedTools(draft);
                          Navigator.pop(ctx);
                        },
                        child: Text('使用 ${draft.length} 个工具'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openGenOptions() async {
    final gen = ref.read(genOptionsProvider);
    var temp = gen.temperature ?? 0.7;
    var maxTokens = gen.maxTokens ?? 2048;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('生成参数', style: Theme.of(ctx).textTheme.titleMedium),
                  ListTile(
                    title: Text('Temperature: ${temp.toStringAsFixed(2)}'),
                    subtitle: Slider(
                      value: temp,
                      min: 0,
                      max: 2,
                      divisions: 40,
                      onChanged: (v) => setLocal(() => temp = v),
                    ),
                  ),
                  ListTile(
                    title: Text('Max tokens: $maxTokens'),
                    subtitle: Slider(
                      value: maxTokens.toDouble(),
                      min: 256,
                      max: 8192,
                      divisions: 31,
                      onChanged: (v) => setLocal(() => maxTokens = v.round()),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await ref
                          .read(genOptionsProvider.notifier)
                          .setTemperature(temp);
                      await ref
                          .read(genOptionsProvider.notifier)
                          .setMaxTokens(maxTokens);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _newChat() {
    // Start a clean draft session on the home route ('' key).
    ref.read(chatControllerProvider('').notifier).resetDraft();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider(widget.conversationId));
    final notifier = ref.read(
      chatControllerProvider(widget.conversationId).notifier,
    );
    final modelsAsync = ref.watch(modelsListProvider);
    final modelList = modelsAsync.asData?.value ?? const [];
    final modelNames = modelList.map((m) => m.platformModelName).toList();
    final modelSubtitles = {
      for (final m in modelList)
        m.platformModelName: [
          if (m.vendor.isNotEmpty) m.vendor,
          if (m.capabilityTags.isNotEmpty) m.capabilityTags.take(3).join(', '),
          if (m.pricingSummary != null) m.pricingSummary!,
        ].where((e) => e.isNotEmpty).join(' · '),
    };

    final onlineAsync = ref.watch(connectivityOnlineProvider);
    final online =
        onlineAsync.asData?.value ??
        ref.watch(connectivityInitialProvider).asData?.value ??
        true;
    final sendWithEnter = ref.watch(sendWithEnterProvider);
    final bubbleStyle = ref.watch(bubbleStyleProvider);
    final compact = bubbleStyle == 'compact';
    final visible = state.visibleMessages;

    ref.listen(chatControllerProvider(widget.conversationId), (prev, next) {
      final prevVis = prev?.visibleMessages ?? const [];
      final nextVis = next.visibleMessages;
      final prevLast = prevVis.isNotEmpty ? prevVis.last.content : null;
      final nextLast = nextVis.isNotEmpty ? nextVis.last.content : null;
      if (prevVis.length != nextVis.length ||
          prev?.isStreaming != next.isStreaming ||
          prev?.branchIndexByParent != next.branchIndexByParent ||
          (next.isStreaming && prevLast != nextLast)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      drawer: ChatDrawer(
        activeConversationId:
            state.boundConversationId ??
            (widget.conversationId.isEmpty ? null : widget.conversationId),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            tooltip: '会话历史',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AssistantAvatar(size: 26),
            const SizedBox(width: 10),
            Text('对话', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          if (state.isStreaming)
            IconButton(
              tooltip: '停止',
              onPressed: notifier.stopStreaming,
              icon: const Icon(Icons.stop_circle_rounded),
            ),
          IconButton(
            tooltip: '新对话',
            onPressed: state.isStreaming ? null : _newChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            tooltip: '工具',
            onPressed: state.isStreaming ? null : () => _pickTools(state),
            icon: Badge(
              isLabelVisible: state.selectedToolIds.isNotEmpty,
              label: Text('${state.selectedToolIds.length}'),
              child: const Icon(Icons.extension_outlined),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '更多',
            icon: const Icon(Icons.more_vert_rounded),
            enabled: !state.isStreaming,
            onSelected: (value) {
              switch (value) {
                case 'prompt':
                  _pickPreset();
                case 'regenerate':
                  notifier.regenerate();
                case 'export':
                  _exportMenu();
                case 'reload':
                  notifier.loadMessages();
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'prompt',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.auto_awesome_outlined),
                  title: Text('提示词预设'),
                ),
              ),
              PopupMenuItem(
                value: 'regenerate',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.refresh_rounded),
                  title: Text('重新生成'),
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.ios_share_rounded),
                  title: Text('导出对话'),
                ),
              ),
              PopupMenuItem(
                value: 'reload',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.history_rounded),
                  title: Text('刷新消息'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (!online) const OfflineBanner(),
          if (state.isLoadingMore) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const LoadingView(message: '加载消息…')
                : visible.isEmpty
                ? const EmptyState(
                    useBrandMark: true,
                    title: '开始新的对话',
                    message: '发送第一条消息即可开始。\n右上角可切换提示词与工具。',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final m = visible[index];
                      final isLastAssistant =
                          index == visible.length - 1 &&
                          m.role == MessageRole.assistant;
                      final isUser = m.role == MessageRole.user;
                      final siblings = state.branchSiblings(m.parentPublicID);
                      final branchTotal =
                          m.role == MessageRole.assistant && siblings.length > 1
                          ? siblings.length
                          : null;
                      final branchIndex = branchTotal == null
                          ? null
                          : siblings
                                .indexWhere((s) => s.id == m.id)
                                .clamp(0, siblings.length - 1);
                      return MessageBubble(
                        message: m,
                        compact: compact,
                        branchIndex: branchIndex,
                        branchTotal: branchTotal,
                        onBranchPrev:
                            branchTotal != null && m.parentPublicID != null
                            ? () => notifier.selectBranchRelative(
                                m.parentPublicID!,
                                -1,
                              )
                            : null,
                        onBranchNext:
                            branchTotal != null && m.parentPublicID != null
                            ? () => notifier.selectBranchRelative(
                                m.parentPublicID!,
                                1,
                              )
                            : null,
                        onCopy: () => _copy(m.content),
                        onRegenerate: isLastAssistant
                            ? notifier.regenerate
                            : null,
                        onRetry: m.error != null
                            ? notifier.retryLastFailed
                            : null,
                        onFeedback: m.role == MessageRole.assistant
                            ? (fb) => notifier.setFeedback(m.id, fb)
                            : null,
                        onEdit: isUser && !state.isStreaming
                            ? () => _editMessage(m.id, m.content)
                            : null,
                        onLongPress: () => _showMessageActions(
                          ChatMessageActions(
                            messageId: m.id,
                            content: m.content,
                            canRegenerate:
                                isLastAssistant && !state.isStreaming,
                            canRetry: m.error != null && !state.isStreaming,
                            canEdit: isUser && !state.isStreaming,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (state.error != null && state.messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ChatInput(
            isStreaming: state.isStreaming,
            attachments: state.attachments,
            selectedModel: state.selectedModel,
            models: modelNames,
            modelSubtitles: modelSubtitles,
            sendWithEnter: sendWithEnter,
            onModelChanged: (m) {
              notifier.setModel(m);
              if (m != null) {
                ref.read(defaultModelProvider.notifier).setModel(m);
              }
            },
            onOpenGenOptions: _openGenOptions,
            onSend: notifier.send,
            onStop: notifier.stopStreaming,
            onPickImage: _pick,
            onPickFiles: _pickFiles,
            onRemoveAttachment: notifier.removeAttachmentAt,
          ),
        ],
      ),
    );
  }
}

class ChatMessageActions {
  const ChatMessageActions({
    required this.messageId,
    required this.content,
    required this.canRegenerate,
    required this.canRetry,
    this.canEdit = false,
  });

  final String messageId;
  final String content;
  final bool canRegenerate;
  final bool canRetry;
  final bool canEdit;
}
