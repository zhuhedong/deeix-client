import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/settings/app_preferences.dart';
import '../../../core/utils/stream_events.dart';
import '../../../shared/models/file_object.dart';
import '../../../shared/models/message.dart';
import '../../../shared/models/message_attachment.dart';
import '../../conversation/data/conversation_repository.dart';
import '../../conversation/presentation/conversation_controller.dart';
import '../../file/data/file_repository.dart';
import '../data/chat_repository.dart';

class PendingAttachment {
  const PendingAttachment({
    required this.localPath,
    required this.fileName,
    this.file,
    this.uploadProgress = 0,
    this.uploading = false,
    this.error,
  });

  final String localPath;
  final String fileName;
  final FileObject? file;
  final double uploadProgress;
  final bool uploading;
  final String? error;

  PendingAttachment copyWith({
    FileObject? file,
    double? uploadProgress,
    bool? uploading,
    String? error,
    bool clearError = false,
    bool clearFile = false,
  }) {
    return PendingAttachment(
      localPath: localPath,
      fileName: fileName,
      file: clearFile ? null : (file ?? this.file),
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploading: uploading ?? this.uploading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isStreaming = false,
    this.error,
    this.selectedModel,
    this.attachments = const [],
    this.selectedToolIds = const {},
    this.messagePage = 1,
    this.messageTotal = 0,
    this.hasMoreMessages = false,
    this.branchIndexByParent = const {},
    this.boundConversationId,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isStreaming;
  final String? error;
  final String? selectedModel;
  final List<PendingAttachment> attachments;
  final Set<int> selectedToolIds;
  final int messagePage;
  final int messageTotal;
  final bool hasMoreMessages;

  /// Real server conversation id once a draft has been created on first send.
  /// Null while still an empty draft or for an already-persisted conversation.
  final String? boundConversationId;

  /// parentPublicID → selected sibling index for assistant branches.
  final Map<String, int> branchIndexByParent;

  /// Messages after applying branch visibility (for ListView).
  List<ChatMessage> get visibleMessages => filterBranchVisibleMessages(
    messages,
    selectedIndexByParent: branchIndexByParent,
  );

  /// Sibling assistants under [parentPublicID] (all, not filtered).
  List<ChatMessage> branchSiblings(String? parentPublicID) {
    if (parentPublicID == null || parentPublicID.isEmpty) return const [];
    return messages
        .where(
          (m) =>
              m.role == MessageRole.assistant &&
              m.parentPublicID == parentPublicID,
        )
        .toList();
  }

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isStreaming,
    String? error,
    String? selectedModel,
    List<PendingAttachment>? attachments,
    Set<int>? selectedToolIds,
    int? messagePage,
    int? messageTotal,
    bool? hasMoreMessages,
    Map<String, int>? branchIndexByParent,
    String? boundConversationId,
    bool clearError = false,
    bool clearSelectedModel = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isStreaming: isStreaming ?? this.isStreaming,
      error: clearError ? null : (error ?? this.error),
      selectedModel: clearSelectedModel
          ? null
          : (selectedModel ?? this.selectedModel),
      attachments: attachments ?? this.attachments,
      selectedToolIds: selectedToolIds ?? this.selectedToolIds,
      messagePage: messagePage ?? this.messagePage,
      messageTotal: messageTotal ?? this.messageTotal,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      branchIndexByParent: branchIndexByParent ?? this.branchIndexByParent,
      boundConversationId: boundConversationId ?? this.boundConversationId,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  ChatController(this.conversationId);

  final String conversationId;

  /// The live target id. Equals [conversationId] for a persisted chat, or ''
  /// for a draft until the first send creates the server conversation.
  late String _convId;
  CancelToken? _cancelToken;
  String? _activeRunId;
  static const _pageSize = 50;

  bool get isDraft => _convId.isEmpty;

  @override
  ChatState build() {
    _convId = conversationId;
    ref.onDispose(() {
      _cancelToken?.cancel('disposed');
    });
    Future.microtask(() async {
      final defaultModel = ref.read(defaultModelProvider);
      if (defaultModel != null) {
        state = state.copyWith(selectedModel: defaultModel);
      }
      if (_convId.isNotEmpty) {
        await loadMessages();
      }
    });
    return ChatState(isLoading: conversationId.isNotEmpty);
  }

  /// Reset the home draft back to a clean, empty new session.
  void resetDraft() {
    _cancelToken?.cancel('reset-draft');
    _cancelToken = null;
    _activeRunId = null;
    _convId = conversationId;
    final defaultModel = ref.read(defaultModelProvider);
    state = ChatState(selectedModel: defaultModel);
  }

  Future<ChatRepository> get _repo => ref.read(chatRepositoryProvider.future);
  Future<FileRepository> get _files => ref.read(fileRepositoryProvider.future);

  void setModel(String? model) {
    state = state.copyWith(
      selectedModel: model,
      clearSelectedModel: model == null,
    );
  }

  void toggleTool(int toolId) {
    final next = {...state.selectedToolIds};
    if (!next.add(toolId)) next.remove(toolId);
    state = state.copyWith(selectedToolIds: next);
  }

  void setSelectedTools(Set<int> ids) {
    state = state.copyWith(selectedToolIds: ids);
  }

  /// Select which sibling branch to show under [parentPublicID].
  void selectBranch(String parentPublicID, int index) {
    if (parentPublicID.isEmpty) return;
    final siblings = state.branchSiblings(parentPublicID);
    if (siblings.isEmpty) return;
    final next = {...state.branchIndexByParent};
    next[parentPublicID] = index.clamp(0, siblings.length - 1);
    state = state.copyWith(branchIndexByParent: next);
  }

  void selectBranchRelative(String parentPublicID, int delta) {
    final siblings = state.branchSiblings(parentPublicID);
    if (siblings.length <= 1) return;
    final current =
        state.branchIndexByParent[parentPublicID] ?? (siblings.length - 1);
    selectBranch(parentPublicID, current + delta);
  }

  Future<Map<String, dynamic>> exportJson() async {
    final repo = await _repo;
    return repo.exportConversation(_convId);
  }

  String exportMarkdown() => messagesToMarkdown(state.visibleMessages);

  /// After loading messages, default each branch group to the latest sibling.
  void _syncBranchDefaults(List<ChatMessage> messages) {
    final groups = groupAssistantBranches(messages);
    if (groups.isEmpty) return;
    final next = {...state.branchIndexByParent};
    var changed = false;
    for (final e in groups.entries) {
      if (!next.containsKey(e.key) && e.value.length > 1) {
        next[e.key] = e.value.length - 1;
        changed = true;
      }
    }
    if (changed) {
      state = state.copyWith(branchIndexByParent: next);
    }
  }

  Future<void> loadMessages() async {
    if (_convId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = await _repo;
      final page = await repo.listMessagesPage(
        _convId,
        page: 1,
        pageSize: _pageSize,
      );
      // API usually returns chronological or reverse — keep as returned.
      state = state.copyWith(
        messages: page.results,
        isLoading: false,
        messagePage: 1,
        messageTotal: page.total,
        hasMoreMessages: page.results.length < page.total,
      );
      _syncBranchDefaults(page.results);
    } catch (e) {
      state = state.copyWith(
        messages: const [],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadOlderMessages() async {
    if (_convId.isEmpty) return;
    if (state.isLoading || state.isLoadingMore || !state.hasMoreMessages) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final next = state.messagePage + 1;
      final repo = await _repo;
      final page = await repo.listMessagesPage(
        _convId,
        page: next,
        pageSize: _pageSize,
      );
      final existingIds = state.messages.map((m) => m.id).toSet();
      final older = page.results.where((m) => !existingIds.contains(m.id));
      state = state.copyWith(
        messages: [...older, ...state.messages],
        isLoadingMore: false,
        messagePage: next,
        messageTotal: page.total,
        hasMoreMessages: state.messages.length + older.length < page.total,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> addLocalFile(String path, {String? fileName}) async {
    final name = fileName ?? path.split(Platform.pathSeparator).last;
    final pending = PendingAttachment(
      localPath: path,
      fileName: name,
      uploading: true,
    );
    state = state.copyWith(attachments: [...state.attachments, pending]);
    final index = state.attachments.length - 1;

    try {
      final repo = await _files;
      final uploaded = await repo.upload(
        file: File(path),
        fileName: name,
        purpose: 'chat',
        onProgress: (sent, total) {
          if (total <= 0) return;
          final list = [...state.attachments];
          if (index >= list.length) return;
          list[index] = list[index].copyWith(
            uploadProgress: sent / total,
            uploading: true,
          );
          state = state.copyWith(attachments: list);
        },
      );
      final list = [...state.attachments];
      if (index < list.length) {
        list[index] = list[index].copyWith(
          file: uploaded,
          uploadProgress: 1,
          uploading: false,
          clearError: true,
        );
        state = state.copyWith(attachments: list);
      }
    } catch (e) {
      final list = [...state.attachments];
      if (index < list.length) {
        list[index] = list[index].copyWith(
          uploading: false,
          error: e.toString(),
        );
        state = state.copyWith(attachments: list);
      }
    }
  }

  void removeAttachmentAt(int index) {
    if (index < 0 || index >= state.attachments.length) return;
    final list = [...state.attachments]..removeAt(index);
    state = state.copyWith(attachments: list);
  }

  Future<void> send(String text) async {
    final content = text.trim();
    final readyFiles = state.attachments
        .where((a) => a.file != null && a.error == null && !a.uploading)
        .map((a) => a.file!.fileID)
        .toList();
    final hasUploading = state.attachments.any((a) => a.uploading);
    if (hasUploading) return;
    if (content.isEmpty && readyFiles.isEmpty) return;
    if (state.isStreaming) return;

    final contentType = readyFiles.isEmpty
        ? 'text'
        : (content.isEmpty ? 'image' : 'mixed');

    final localAttachments = state.attachments
        .where((a) => a.file != null && a.error == null && !a.uploading)
        .map(
          (a) => MessageAttachment(
            fileID: a.file!.fileID,
            fileName: a.fileName,
            mimeType: a.file!.mimeType,
            fileCategory: a.file!.fileCategory,
            sizeBytes: a.file!.sizeBytes,
            kind: a.file!.isImage ? 'image' : 'file',
            processingReady: a.file!.processingReady,
            localPath: a.localPath,
          ),
        )
        .toList();

    await _streamSend(
      content: content.isEmpty ? ' ' : content,
      contentType: contentType,
      fileIds: readyFiles,
      localAttachments: localAttachments,
      clearAttachments: true,
    );
  }

  Future<void> regenerate() async {
    if (state.isStreaming || state.messages.isEmpty) return;

    // Prefer last *visible* assistant so branch UI matches action.
    final visible = state.visibleMessages;
    ChatMessage? assistant;
    ChatMessage? user;
    for (var i = visible.length - 1; i >= 0; i--) {
      if (visible[i].role == MessageRole.assistant) {
        assistant = visible[i];
        if (i > 0 && visible[i - 1].role == MessageRole.user) {
          user = visible[i - 1];
        }
        break;
      }
    }
    if (assistant == null) {
      for (var i = state.messages.length - 1; i >= 0; i--) {
        if (state.messages[i].role == MessageRole.assistant) {
          assistant = state.messages[i];
          if (i > 0 && state.messages[i - 1].role == MessageRole.user) {
            user = state.messages[i - 1];
          }
          break;
        }
      }
    }
    if (assistant == null) return;

    final parentId = user != null && !user.id.startsWith('local-')
        ? user.id
        : assistant.parentPublicID;
    final content = user?.content ?? '';
    await _streamSend(
      content: content.isEmpty ? ' ' : content,
      contentType: 'text',
      branchReason: 'retry',
      sourceMessagePublicID: assistant.id.startsWith('local-')
          ? null
          : assistant.id,
      parentMessagePublicID: parentId,
      // Retry creates a sibling assistant under the same parent user message.
      appendLocalPair: false,
      appendLocalAssistantOnly: true,
    );
  }

  Future<void> retryLastFailed() async {
    if (state.isStreaming || state.messages.isEmpty) return;
    final last = state.messages.last;
    if (last.role == MessageRole.assistant && last.error != null) {
      await regenerate();
      return;
    }
    // Retry last user message
    ChatMessage? user;
    for (var i = state.messages.length - 1; i >= 0; i--) {
      if (state.messages[i].role == MessageRole.user) {
        user = state.messages[i];
        break;
      }
    }
    if (user == null) return;
    await _streamSend(
      content: user.content,
      contentType: user.contentType,
      appendLocalPair: true,
    );
  }

  /// Edit prior user message content and resend with branchReason=edit.
  Future<void> editAndResend(String userMessageId, String newContent) async {
    if (state.isStreaming) return;
    final text = newContent.trim();
    if (text.isEmpty) return;

    final idx = state.messages.indexWhere((m) => m.id == userMessageId);
    if (idx < 0) return;
    final original = state.messages[idx];
    if (original.role != MessageRole.user) return;

    // Truncate messages after the edited one for local UI.
    final kept = state.messages.take(idx).toList();
    state = state.copyWith(messages: kept);

    await _streamSend(
      content: text,
      contentType: 'text',
      branchReason: 'edit',
      sourceMessagePublicID: original.id.startsWith('local-')
          ? null
          : original.id,
      parentMessagePublicID: original.id.startsWith('local-')
          ? null
          : original.id,
      appendLocalPair: true,
    );
  }

  Future<void> setFeedback(String messageId, String? feedback) async {
    if (messageId.startsWith('local-')) return;
    try {
      final repo = await _repo;
      await repo.setFeedback(messageId, feedback);
      final list = state.messages.map((m) {
        if (m.id != messageId) return m;
        return m.copyWith(myFeedback: feedback);
      }).toList();
      state = state.copyWith(messages: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _streamSend({
    required String content,
    required String contentType,
    List<String>? fileIds,
    List<MessageAttachment> localAttachments = const [],
    String? branchReason,
    String? parentMessagePublicID,
    String? sourceMessagePublicID,
    bool clearAttachments = false,
    bool appendLocalPair = true,
    bool appendLocalAssistantOnly = false,
  }) async {
    // A draft's first send materializes the server conversation.
    final didBind = _convId.isEmpty;
    if (didBind) {
      try {
        final convRepo = await ref.read(conversationRepositoryProvider.future);
        final created = await convRepo.create(model: state.selectedModel);
        _convId = created.publicID;
        state = state.copyWith(boundConversationId: _convId);
        unawaited(ref.read(conversationListProvider.notifier).refresh());
      } catch (e) {
        state = state.copyWith(error: '创建对话失败: $e');
        return;
      }
    }

    if (appendLocalPair) {
      final userMsg = ChatMessage.localUser(
        content.trim(),
        attachments: localAttachments,
        contentType: contentType,
        parentPublicID: parentMessagePublicID,
        sourcePublicID: sourceMessagePublicID,
        branchReason: branchReason,
      );
      final assistantMsg = ChatMessage.streamingAssistant(
        parentPublicID: parentMessagePublicID ?? userMsg.id,
        sourcePublicID: sourceMessagePublicID,
        branchReason: branchReason,
      );
      state = state.copyWith(
        messages: [...state.messages, userMsg, assistantMsg],
        isStreaming: true,
        clearError: true,
        attachments: clearAttachments ? const [] : state.attachments,
      );
    } else if (appendLocalAssistantOnly) {
      final assistantMsg = ChatMessage.streamingAssistant(
        parentPublicID: parentMessagePublicID,
        sourcePublicID: sourceMessagePublicID,
        branchReason: branchReason,
      );
      final nextBranch = {...state.branchIndexByParent};
      if (parentMessagePublicID != null && parentMessagePublicID.isNotEmpty) {
        final siblings = [
          ...state.branchSiblings(parentMessagePublicID),
          assistantMsg,
        ];
        nextBranch[parentMessagePublicID] = siblings.length - 1;
      }
      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isStreaming: true,
        clearError: true,
        branchIndexByParent: nextBranch,
        attachments: clearAttachments ? const [] : state.attachments,
      );
    } else {
      state = state.copyWith(isStreaming: true, clearError: true);
    }

    _cancelToken?.cancel('new-send');
    _cancelToken = CancelToken();
    _activeRunId = null;

    try {
      final repo = await _repo;
      final buffer = StringBuffer();
      final thinkBuf = StringBuffer();
      String? processStatus;
      String? toolSummary;
      String? ragSummary;
      List<String> ragSources = const [];
      String? fileProcMessage;
      final gen = ref.read(genOptionsProvider);

      await for (final chunk in repo.streamMessage(
        conversationPublicId: _convId,
        content: content,
        contentType: contentType,
        model: state.selectedModel,
        fileIds: fileIds,
        branchReason: branchReason,
        parentMessagePublicID: parentMessagePublicID,
        sourceMessagePublicID: sourceMessagePublicID,
        options: gen.toOptionsMap(),
        selectedToolIds: state.selectedToolIds.toList(),
        cancelToken: _cancelToken,
      )) {
        final runId =
            chunk.raw?['runID'] as String? ??
            chunk.finalAssistantMessage?.runID;
        if (runId != null && runId.isNotEmpty) {
          _activeRunId = runId;
        }

        if (chunk.thinkDelta != null && chunk.thinkDelta!.isNotEmpty) {
          thinkBuf.write(chunk.thinkDelta);
        }
        if (chunk.processStatus != null) processStatus = chunk.processStatus;
        if (chunk.toolSummary != null) toolSummary = chunk.toolSummary;
        if (chunk.fileProcMessage != null) {
          fileProcMessage = chunk.fileProcMessage;
        }
        if (chunk.ragSummary != null) ragSummary = chunk.ragSummary;
        if (chunk.ragSources != null && chunk.ragSources!.isNotEmpty) {
          ragSources = chunk.ragSources!;
        }

        if (chunk.delta != null && chunk.delta!.isNotEmpty) {
          buffer.write(chunk.delta);
        }

        if (chunk.delta != null ||
            chunk.thinkDelta != null ||
            chunk.processStatus != null ||
            chunk.toolSummary != null ||
            chunk.fileProcMessage != null ||
            chunk.ragSummary != null ||
            chunk.ragSources != null) {
          _updateLastAssistant(
            buffer.toString(),
            isStreaming: true,
            thinking: thinkBuf.toString(),
            processStatus: processStatus,
            toolSummary: toolSummary,
            ragSummary: ragSummary,
            ragSources: ragSources,
            fileProcMessage: fileProcMessage,
          );
        }

        if (chunk.error != null) {
          _updateLastAssistant(
            buffer.isNotEmpty ? buffer.toString() : '',
            isStreaming: false,
            error: chunk.error,
            thinking: thinkBuf.toString(),
            processStatus: processStatus,
            toolSummary: toolSummary,
            ragSummary: ragSummary,
            ragSources: ragSources,
            fileProcMessage: fileProcMessage,
          );
          state = state.copyWith(isStreaming: false, error: chunk.error);
          return;
        }

        if (chunk.done) {
          if (chunk.finalUserMessage != null ||
              chunk.finalAssistantMessage != null) {
            final list = [...state.messages];
            if (list.isNotEmpty && list.last.role == MessageRole.assistant) {
              if (list.length >= 2 &&
                  list[list.length - 2].role == MessageRole.user &&
                  chunk.finalUserMessage != null) {
                list[list.length - 2] = chunk.finalUserMessage!;
              }
              if (chunk.finalAssistantMessage != null) {
                final fin = chunk.finalAssistantMessage!;
                list[list.length - 1] = fin.copyWith(
                  isStreaming: false,
                  thinking: thinkBuf.isNotEmpty
                      ? thinkBuf.toString()
                      : fin.thinking,
                  processStatus: processStatus ?? fin.processStatus,
                  toolSummary: toolSummary ?? fin.toolSummary,
                  ragSummary: ragSummary ?? fin.ragSummary,
                  ragSources: ragSources.isNotEmpty
                      ? ragSources
                      : fin.ragSources,
                  fileProcMessage: fileProcMessage ?? fin.fileProcMessage,
                  parentPublicID: fin.parentPublicID ?? parentMessagePublicID,
                  sourcePublicID: fin.sourcePublicID ?? sourceMessagePublicID,
                  branchReason: fin.branchReason ?? branchReason,
                );
                _activeRunId = fin.runID;
                final parent = list.last.parentPublicID;
                if (parent != null && parent.isNotEmpty) {
                  final siblings = list
                      .where(
                        (m) =>
                            m.role == MessageRole.assistant &&
                            m.parentPublicID == parent,
                      )
                      .toList();
                  final nextBranch = {...state.branchIndexByParent};
                  nextBranch[parent] = siblings.length - 1;
                  state = state.copyWith(
                    messages: list,
                    isStreaming: false,
                    branchIndexByParent: nextBranch,
                  );
                } else {
                  state = state.copyWith(messages: list, isStreaming: false);
                }
              } else {
                list[list.length - 1] = list.last.copyWith(
                  content: buffer.toString(),
                  isStreaming: false,
                  thinking: thinkBuf.toString(),
                  processStatus: processStatus,
                  toolSummary: toolSummary,
                  ragSummary: ragSummary,
                  ragSources: ragSources,
                  fileProcMessage: fileProcMessage,
                );
                state = state.copyWith(messages: list, isStreaming: false);
              }
            } else {
              _updateLastAssistant(
                buffer.toString(),
                isStreaming: false,
                thinking: thinkBuf.toString(),
                processStatus: processStatus,
                toolSummary: toolSummary,
                ragSummary: ragSummary,
                ragSources: ragSources,
                fileProcMessage: fileProcMessage,
              );
              state = state.copyWith(isStreaming: false);
            }
          } else {
            _updateLastAssistant(
              buffer.toString(),
              isStreaming: false,
              thinking: thinkBuf.toString(),
              processStatus: processStatus,
              toolSummary: toolSummary,
              ragSummary: ragSummary,
              ragSources: ragSources,
              fileProcMessage: fileProcMessage,
            );
            state = state.copyWith(isStreaming: false);
          }
          return;
        }
      }

      _updateLastAssistant(
        buffer.toString(),
        isStreaming: false,
        thinking: thinkBuf.toString(),
        processStatus: processStatus,
        toolSummary: toolSummary,
        ragSummary: ragSummary,
        ragSources: ragSources,
        fileProcMessage: fileProcMessage,
      );
      state = state.copyWith(isStreaming: false);
    } on DioException catch (e) {
      final cancelled = e.type == DioExceptionType.cancel;
      final lastContent = state.messages.isNotEmpty
          ? state.messages.last.content
          : '';
      final err = cancelled ? '已取消' : (e.message ?? e.toString());
      _updateLastAssistant(lastContent, isStreaming: false, error: err);
      state = state.copyWith(isStreaming: false, error: err);
    } on ApiException catch (e) {
      final lastContent = state.messages.isNotEmpty
          ? state.messages.last.content
          : '';
      _updateLastAssistant(lastContent, isStreaming: false, error: e.message);
      state = state.copyWith(isStreaming: false, error: e.message);
    } catch (e) {
      final lastContent = state.messages.isNotEmpty
          ? state.messages.last.content
          : '';
      _updateLastAssistant(
        lastContent,
        isStreaming: false,
        error: e.toString(),
      );
      state = state.copyWith(isStreaming: false, error: e.toString());
    } finally {
      // Refresh history so a freshly-created chat (and its server title)
      // appears in the drawer.
      if (didBind) {
        unawaited(ref.read(conversationListProvider.notifier).refresh());
      }
    }
  }

  Future<void> stopStreaming() async {
    final runId = _activeRunId;
    _cancelToken?.cancel('user-stop');
    _cancelToken = null;
    if (runId != null && runId.isNotEmpty) {
      try {
        final repo = await _repo;
        await repo.cancelRun(runId);
      } catch (_) {}
    }
    if (state.messages.isNotEmpty && state.messages.last.isStreaming) {
      _updateLastAssistant(state.messages.last.content, isStreaming: false);
    }
    state = state.copyWith(isStreaming: false);
  }

  void _updateLastAssistant(
    String content, {
    required bool isStreaming,
    String? error,
    String? thinking,
    String? processStatus,
    String? toolSummary,
    String? ragSummary,
    List<String>? ragSources,
    String? fileProcMessage,
  }) {
    final list = [...state.messages];
    if (list.isEmpty) return;
    final last = list.last;
    if (last.role != MessageRole.assistant) return;
    list[list.length - 1] = last.copyWith(
      content: content,
      isStreaming: isStreaming,
      error: error,
      thinking: thinking ?? last.thinking,
      processStatus: processStatus ?? last.processStatus,
      toolSummary: toolSummary ?? last.toolSummary,
      ragSummary: ragSummary ?? last.ragSummary,
      ragSources: ragSources ?? last.ragSources,
      fileProcMessage: fileProcMessage ?? last.fileProcMessage,
    );
    state = state.copyWith(messages: list);
  }
}

final chatControllerProvider =
    NotifierProvider.family<ChatController, ChatState, String>(
      ChatController.new,
    );
