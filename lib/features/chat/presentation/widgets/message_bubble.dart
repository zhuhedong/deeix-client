import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../../shared/models/message.dart';
import '../../../../shared/models/message_attachment.dart';
import '../../../../shared/theme/app_tokens.dart';
import '../../../../shared/widgets/auth_network_image.dart';
import '../../../../shared/widgets/file_preview_page.dart';
import '../../../../shared/widgets/ui_kit.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onRegenerate,
    this.onRetry,
    this.onLongPress,
    this.onFeedback,
    this.onEdit,
    this.branchIndex,
    this.branchTotal,
    this.onBranchPrev,
    this.onBranchNext,
    this.compact = false,
  });

  final ChatMessage message;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;
  final ValueChanged<String?>? onFeedback;
  final VoidCallback? onEdit;
  final int? branchIndex;
  final int? branchTotal;
  final VoidCallback? onBranchPrev;
  final VoidCallback? onBranchNext;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, compact ? 4 : 8),
      child: isUser ? _buildUser(context) : _buildAssistant(context),
    );
  }

  // ---------------------------------------------------------------- assistant

  Widget _buildAssistant(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final hasProcess =
        message.thinking.isNotEmpty ||
        message.processStatus != null ||
        message.toolSummary != null ||
        message.ragSummary != null ||
        message.ragSources.isNotEmpty ||
        message.fileProcMessage != null;
    final showTyping =
        message.content.isEmpty &&
        message.isStreaming &&
        message.attachments.isEmpty &&
        message.thinking.isEmpty &&
        message.ragSummary == null &&
        message.fileProcMessage == null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssistantAvatar(size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 6, top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.platformModelName?.isNotEmpty == true
                            ? message.platformModelName!
                            : 'Assistant',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (branchTotal != null &&
                        branchTotal! > 1 &&
                        branchIndex != null)
                      _BranchNav(
                        index: branchIndex!,
                        total: branchTotal!,
                        onPrev: onBranchPrev,
                        onNext: onBranchNext,
                      ),
                  ],
                ),
              ),
              if (hasProcess) _ProcessPanel(message: message),
              GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 15,
                    vertical: compact ? 9 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.assistantBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(compact ? 4 : 6),
                      topRight: Radius.circular(compact ? 14 : 18),
                      bottomLeft: Radius.circular(compact ? 14 : 18),
                      bottomRight: Radius.circular(compact ? 14 : 18),
                    ),
                    border: Border.all(color: tokens.assistantBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.attachments.isNotEmpty)
                        _AttachmentStrip(attachments: message.attachments),
                      if (showTyping)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TypingIndicator(color: scheme.primary),
                        )
                      else if (message.content.trim().isNotEmpty)
                        _AssistantBody(
                          content: message.content,
                          fg: scheme.onSurface,
                        ),
                      if (message.isStreaming && message.content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              TypingIndicator(
                                color: scheme.primary,
                                dotSize: 5,
                              ),
                              const SizedBox(width: 8),
                              Text('生成中', style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (message.error != null)
                _ErrorRow(error: message.error!, onRetry: onRetry),
              if (!message.isStreaming && message.content.trim().isNotEmpty)
                _AssistantActions(
                  message: message,
                  onCopy: onCopy,
                  onRegenerate: onRegenerate,
                  onFeedback: onFeedback,
                ),
              if (message.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 2),
                  child: Text(
                    _formatTime(message.createdAt!),
                    style: theme.textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------- user

  Widget _buildUser(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 15,
                vertical: compact ? 9 : 11,
              ),
              decoration: BoxDecoration(
                gradient: tokens.userBubbleGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(compact ? 14 : 18),
                  topRight: Radius.circular(compact ? 14 : 18),
                  bottomLeft: Radius.circular(compact ? 14 : 18),
                  bottomRight: Radius.circular(compact ? 4 : 6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: tokens.userBubble.last.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.attachments.isNotEmpty)
                    _AttachmentStrip(attachments: message.attachments),
                  if (message.content.trim().isNotEmpty)
                    SelectableText(
                      message.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: tokens.onUserBubble,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                _MiniIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: '编辑重发',
                  onTap: onEdit,
                ),
              if (message.createdAt != null)
                Text(
                  _formatTime(message.createdAt!),
                  style: theme.textTheme.labelSmall,
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _AssistantActions extends StatelessWidget {
  const _AssistantActions({
    required this.message,
    this.onCopy,
    this.onRegenerate,
    this.onFeedback,
  });

  final ChatMessage message;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final ValueChanged<String?>? onFeedback;

  @override
  Widget build(BuildContext context) {
    final hasCode = message.content.contains('```');
    return Padding(
      padding: const EdgeInsets.only(left: 2, top: 6),
      child: Wrap(
        spacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _MiniIconButton(
            icon: Icons.copy_rounded,
            tooltip: '复制',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: message.content));
              onCopy?.call();
            },
          ),
          if (hasCode)
            _MiniIconButton(
              icon: Icons.code_rounded,
              tooltip: '复制代码块',
              onTap: () async {
                final code = _extractFirstCodeBlock(message.content);
                await Clipboard.setData(ClipboardData(text: code));
              },
            ),
          if (onRegenerate != null)
            _MiniIconButton(
              icon: Icons.refresh_rounded,
              tooltip: '重新生成',
              onTap: onRegenerate,
            ),
          if (onFeedback != null) ...[
            _MiniIconButton(
              icon: message.myFeedback == 'up'
                  ? Icons.thumb_up
                  : Icons.thumb_up_outlined,
              tooltip: '点赞',
              active: message.myFeedback == 'up',
              onTap: () =>
                  onFeedback!(message.myFeedback == 'up' ? null : 'up'),
            ),
            _MiniIconButton(
              icon: message.myFeedback == 'down'
                  ? Icons.thumb_down
                  : Icons.thumb_down_outlined,
              tooltip: '点踩',
              active: message.myFeedback == 'down',
              onTap: () =>
                  onFeedback!(message.myFeedback == 'down' ? null : 'down'),
            ),
          ],
        ],
      ),
    );
  }

  static String _extractFirstCodeBlock(String markdown) {
    final match = RegExp(r'```[^\n]*\n([\s\S]*?)```').firstMatch(markdown);
    if (match != null) return match.group(1) ?? markdown;
    return markdown;
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 17,
            color: active ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.error, this.onRetry});

  final String error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: scheme.error,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }
}

class _BranchNav extends StatelessWidget {
  const _BranchNav({
    required this.index,
    required this.total,
    this.onPrev,
    this.onNext,
  });

  final int index;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.softAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BranchArrow(
            icon: Icons.chevron_left_rounded,
            onTap: index <= 0 ? null : onPrev,
          ),
          Text(
            '${index + 1}/$total',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          _BranchArrow(
            icon: Icons.chevron_right_rounded,
            onTap: index >= total - 1 ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _BranchArrow extends StatelessWidget {
  const _BranchArrow({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? scheme.onSurfaceVariant : scheme.primary,
        ),
      ),
    );
  }
}

class _ProcessPanel extends StatelessWidget {
  const _ProcessPanel({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final hasRag = message.ragSummary != null || message.ragSources.isNotEmpty;
    final hasFile =
        message.fileProcMessage != null && message.fileProcMessage!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tokens.softAccent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: message.isStreaming,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          minTileHeight: 40,
          leading: Icon(
            message.isStreaming
                ? Icons.auto_awesome_rounded
                : Icons.psychology_alt_outlined,
            size: 18,
            color: scheme.primary,
          ),
          title: Text(
            message.isStreaming ? '思考 · 检索 · 工具进行中' : '思考过程 · 检索 · 工具',
            style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary),
          ),
          children: [
            if (message.processStatus != null)
              _panelLine(context, '状态: ${message.processStatus}'),
            if (hasFile)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Chip(
                    avatar: Icon(
                      Icons.document_scanner_outlined,
                      size: 15,
                      color: scheme.primary,
                    ),
                    label: Text(message.fileProcMessage!),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            if (hasRag) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 15,
                        color: scheme.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message.ragSummary ??
                              '知识检索 · ${message.ragSources.length} 条',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (message.ragSources.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: message.ragSources
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
            if (message.toolSummary != null && message.toolSummary!.isNotEmpty)
              _panelLine(context, message.toolSummary!, selectable: true),
            if (message.thinking.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: SelectableText(
                    message.thinking,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _panelLine(
    BuildContext context,
    String text, {
    bool selectable = false,
  }) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: selectable
            ? SelectableText(text, style: style)
            : Text(text, style: style),
      ),
    );
  }
}

class _AssistantBody extends StatelessWidget {
  const _AssistantBody({required this.content, required this.fg});
  final String content;
  final Color fg;

  MarkdownStyleSheet _styleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyLarge?.copyWith(color: fg),
      a: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      code: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        color: fg,
        backgroundColor: tokens.codeBackground,
      ),
      codeblockDecoration: BoxDecoration(
        color: tokens.codeBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.codeBorder),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        color: tokens.softAccent,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.hairline)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Split display math blocks $$...$$ for KaTeX-class rendering.
    final parts = content.split(RegExp(r'\$\$'));
    if (parts.length == 1) {
      return MarkdownBody(
        data: content,
        selectable: true,
        styleSheet: _styleSheet(context),
      );
    }
    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      if (i.isOdd) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(
                part.trim(),
                mathStyle: MathStyle.display,
                textStyle: theme.textTheme.bodyLarge,
                onErrorFallback: (_) => SelectableText('\$\$$part\$\$'),
              ),
            ),
          ),
        );
      } else {
        children.add(
          MarkdownBody(
            data: part,
            selectable: true,
            styleSheet: _styleSheet(context),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _AttachmentStrip extends StatelessWidget {
  const _AttachmentStrip({required this.attachments});

  final List<MessageAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = attachments.where((a) => a.isImage).toList();
    final files = attachments.where((a) => !a.isImage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: images.map((a) {
              return GestureDetector(
                onTap: () => openFilePreview(
                  context,
                  fileId: a.fileID.isEmpty ? null : a.fileID,
                  fileName: a.fileName,
                  mimeType: a.mimeType,
                  localPath: a.localPath,
                  processingLabel: a.processingLabel.isEmpty
                      ? null
                      : a.processingLabel,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 128, height: 128, child: _thumb(a)),
                ),
              );
            }).toList(),
          ),
        if (files.isNotEmpty)
          ...files.map(
            (a) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Material(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => openFilePreview(
                    context,
                    fileId: a.fileID.isEmpty ? null : a.fileID,
                    fileName: a.fileName,
                    mimeType: a.mimeType,
                    localPath: a.localPath,
                    processingLabel: a.processingLabel.isEmpty
                        ? null
                        : a.processingLabel,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          a.isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.attach_file_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            a.fileName.isEmpty ? a.fileID : a.fileName,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (a.processingLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            a.processingLabel,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (attachments.isNotEmpty) const SizedBox(height: 8),
      ],
    );
  }

  Widget _thumb(MessageAttachment a) {
    if (a.localPath != null && a.localPath!.isNotEmpty) {
      return Image.file(File(a.localPath!), fit: BoxFit.cover);
    }
    if (a.fileID.isEmpty) {
      return const ColoredBox(
        color: Colors.black12,
        child: Icon(Icons.image_not_supported_outlined),
      );
    }
    return AuthNetworkImage(fileId: a.fileID, fit: BoxFit.cover);
  }
}
