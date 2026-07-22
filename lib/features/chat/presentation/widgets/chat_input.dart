import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_tokens.dart';
import '../chat_controller.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSend,
    this.onStop,
    this.onPickImage,
    this.onPickFiles,
    this.onRemoveAttachment,
    this.enabled = true,
    this.isStreaming = false,
    this.attachments = const [],
    this.selectedModel,
    this.models = const [],
    this.modelSubtitles = const {},
    this.onModelChanged,
    this.onOpenGenOptions,
    this.sendWithEnter = true,
  });

  final ValueChanged<String> onSend;
  final VoidCallback? onStop;
  final Future<void> Function(ImageSource source)? onPickImage;
  final Future<void> Function()? onPickFiles;
  final ValueChanged<int>? onRemoveAttachment;
  final bool enabled;
  final bool isStreaming;
  final List<PendingAttachment> attachments;
  final String? selectedModel;
  final List<String> models;
  final Map<String, String> modelSubtitles;
  final ValueChanged<String?>? onModelChanged;
  final VoidCallback? onOpenGenOptions;
  final bool sendWithEnter;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncHasText);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncHasText);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _syncHasText() {
    final has = _controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _submit() {
    final text = _controller.text;
    if (text.trim().isEmpty && widget.attachments.isEmpty) return;
    if (widget.attachments.any((a) => a.uploading)) return;
    widget.onSend(text);
    _controller.clear();
    _focus.requestFocus();
  }

  Future<void> _showAttachSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.onPickImage != null) ...[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onPickImage!(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onPickImage!(ImageSource.camera);
                },
              ),
            ],
            if (widget.onPickFiles != null)
              ListTile(
                leading: const Icon(Icons.attach_file_rounded),
                title: const Text('选择文件（PDF / 文档等）'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onPickFiles!();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openModelPicker() async {
    if (widget.onModelChanged == null || widget.models.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ModelPickerSheet(
        models: widget.models,
        subtitles: widget.modelSubtitles,
        selected: widget.selectedModel,
      ),
    );
    if (selected != null) {
      widget.onModelChanged!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final canAttach =
        widget.enabled &&
        !widget.isStreaming &&
        (widget.onPickImage != null || widget.onPickFiles != null);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: tokens.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.models.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModelPill(
                        label: widget.selectedModel ?? '选择模型',
                        onTap: widget.isStreaming ? null : _openModelPicker,
                      ),
                    ),
                    if (widget.onOpenGenOptions != null) ...[
                      const SizedBox(width: 6),
                      _RoundIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: '生成参数',
                        onTap: widget.isStreaming
                            ? null
                            : widget.onOpenGenOptions,
                      ),
                    ],
                  ],
                ),
              ),
            if (widget.attachments.isNotEmpty)
              _AttachmentTray(
                attachments: widget.attachments,
                onRemove: widget.onRemoveAttachment,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: tokens.hairline),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _RoundIconButton(
                            icon: Icons.add_rounded,
                            tooltip: '附件',
                            onTap: canAttach ? _showAttachSheet : null,
                          ),
                          Expanded(
                            child: CallbackShortcuts(
                              bindings: {
                                if (widget.sendWithEnter)
                                  const SingleActivator(
                                    LogicalKeyboardKey.enter,
                                  ): () {
                                    if (!widget.isStreaming) _submit();
                                  },
                                const SingleActivator(
                                  LogicalKeyboardKey.enter,
                                  shift: true,
                                ): _insertNewline,
                                if (!widget.sendWithEnter)
                                  const SingleActivator(
                                    LogicalKeyboardKey.enter,
                                    meta: true,
                                  ): () {
                                    if (!widget.isStreaming) _submit();
                                  },
                                if (!widget.sendWithEnter)
                                  const SingleActivator(
                                    LogicalKeyboardKey.enter,
                                    control: true,
                                  ): () {
                                    if (!widget.isStreaming) _submit();
                                  },
                              },
                              child: TextField(
                                controller: _controller,
                                focusNode: _focus,
                                enabled: widget.enabled && !widget.isStreaming,
                                minLines: 1,
                                maxLines: 6,
                                style: theme.textTheme.bodyLarge,
                                textInputAction: widget.sendWithEnter
                                    ? TextInputAction.send
                                    : TextInputAction.newline,
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: widget.isStreaming
                                      ? '生成中…'
                                      : (widget.sendWithEnter
                                            ? '输入消息…'
                                            : '输入消息… ⌘/Ctrl+Enter 发送'),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 12,
                                  ),
                                ),
                                onSubmitted: (_) {
                                  if (!widget.isStreaming &&
                                      widget.sendWithEnter) {
                                    _submit();
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SendButton(
                    isStreaming: widget.isStreaming,
                    enabled:
                        widget.enabled &&
                        (_hasText || widget.attachments.isNotEmpty),
                    onSend: _submit,
                    onStop: widget.onStop,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _insertNewline() {
    final value = _controller.value;
    final sel = value.selection;
    final text = value.text;
    final insertAt = sel.isValid ? sel.start : text.length;
    final next = text.replaceRange(insertAt, insertAt, '\n');
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: insertAt + 1),
    );
  }
}

class _ModelPill extends StatelessWidget {
  const _ModelPill({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    return Material(
      color: tokens.softAccent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.unfold_more_rounded, size: 16, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon),
      iconSize: 22,
      color: scheme.onSurfaceVariant,
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(shape: const CircleBorder()),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isStreaming,
    required this.enabled,
    required this.onSend,
    this.onStop,
  });

  final bool isStreaming;
  final bool enabled;
  final VoidCallback onSend;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    if (isStreaming) {
      return _CircleButton(
        color: scheme.surfaceContainerHighest,
        onTap: onStop,
        child: Icon(Icons.stop_rounded, color: scheme.onSurface, size: 24),
      );
    }

    final active = enabled;
    return _CircleButton(
      gradient: active ? tokens.brandLinearGradient : null,
      color: active ? null : scheme.surfaceContainerHigh,
      shadow: active
          ? [
              BoxShadow(
                color: tokens.brandGradient.last.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
      onTap: active ? onSend : null,
      child: Icon(
        Icons.arrow_upward_rounded,
        color: active ? Colors.white : scheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.child,
    this.onTap,
    this.color,
    this.gradient,
    this.shadow,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _AttachmentTray extends StatelessWidget {
  const _AttachmentTray({required this.attachments, this.onRemove});

  final List<PendingAttachment> attachments;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final a = attachments[index];
          final lower = a.localPath.toLowerCase();
          final isImg =
              a.file?.isImage == true ||
              lower.endsWith('.png') ||
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.webp');
          final proc = a.file?.processingLabel ?? '';
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: isImg
                      ? Image.file(File(a.localPath), fit: BoxFit.cover)
                      : Container(
                          color: scheme.surfaceContainerHigh,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    a.file?.isPdf == true ||
                                            a.fileName.toLowerCase().endsWith(
                                              '.pdf',
                                            )
                                        ? Icons.picture_as_pdf_outlined
                                        : Icons.insert_drive_file_outlined,
                                    size: 22,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    a.fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              if (a.uploading)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: Center(
                        child: SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            value: a.uploadProgress > 0
                                ? a.uploadProgress
                                : null,
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!a.uploading &&
                  proc.isNotEmpty &&
                  a.file?.processingReady != true)
                Positioned(
                  left: 3,
                  bottom: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      proc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
              if (a.error != null)
                const Positioned(
                  left: 4,
                  bottom: 4,
                  child: Icon(Icons.error, color: Colors.red, size: 18),
                ),
              Positioned(
                right: -6,
                top: -6,
                child: GestureDetector(
                  onTap: onRemove == null ? null : () => onRemove!(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.inverseSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: scheme.onInverseSurface,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModelPickerSheet extends StatefulWidget {
  const _ModelPickerSheet({
    required this.models,
    required this.subtitles,
    this.selected,
  });

  final List<String> models;
  final Map<String, String> subtitles;
  final String? selected;

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  final _query = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final q = _filter.trim().toLowerCase();
    final filtered = widget.models.where((m) {
      if (q.isEmpty) return true;
      final sub = (widget.subtitles[m] ?? '').toLowerCase();
      return m.toLowerCase().contains(q) || sub.contains(q);
    }).toList();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text('选择模型', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _query,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索模型 / 能力 / 价格…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _filter.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _query.clear();
                            setState(() => _filter = '');
                          },
                        ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        '无匹配模型',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final m = filtered[i];
                        final sub = widget.subtitles[m];
                        final selected = widget.selected == m;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? context.tokens.softAccent
                                : scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? scheme.primary.withValues(alpha: 0.4)
                                  : context.tokens.hairline,
                            ),
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            title: Text(m, style: theme.textTheme.titleSmall),
                            subtitle: sub == null || sub.isEmpty
                                ? null
                                : Text(sub, maxLines: 2),
                            trailing: selected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: scheme.primary,
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, m),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
