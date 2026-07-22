import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/conversation.dart';
import '../data/conversation_repository.dart';

/// List filter matching API `status`: active | archived | all
enum ConversationFilter { active, archived }

class ConversationListState {
  const ConversationListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.page = 1,
    this.total = 0,
    this.hasMore = true,
    this.query = '',
    this.filter = ConversationFilter.active,
  });

  final List<Conversation> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int page;
  final int total;
  final bool hasMore;
  final String query;
  final ConversationFilter filter;

  String get statusParam =>
      filter == ConversationFilter.archived ? 'archived' : 'active';

  ConversationListState copyWith({
    List<Conversation>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? page,
    int? total,
    bool? hasMore,
    String? query,
    ConversationFilter? filter,
    bool clearError = false,
  }) {
    return ConversationListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }
}

class ConversationListController extends Notifier<ConversationListState> {
  static const _pageSize = 30;

  @override
  ConversationListState build() {
    Future.microtask(refresh);
    return const ConversationListState(isLoading: true);
  }

  Future<ConversationRepository> get _repo =>
      ref.read(conversationRepositoryProvider.future);

  void _sort(List<Conversation> items) {
    items.sort((a, b) {
      if (a.isStarred != b.isStarred) return a.isStarred ? -1 : 1;
      final at = a.updatedAt ?? a.createdAt ?? DateTime(1970);
      final bt = b.updatedAt ?? b.createdAt ?? DateTime(1970);
      return bt.compareTo(at);
    });
  }

  Future<void> setFilter(ConversationFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter, page: 1);
    await refresh();
  }

  Future<void> refresh({String? query}) async {
    final q = query ?? state.query;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      query: q,
      page: 1,
    );
    try {
      final repo = await _repo;
      final pageData = await repo.listPage(
        page: 1,
        pageSize: _pageSize,
        status: state.statusParam,
        query: q.isEmpty ? null : q,
      );
      final items = [...pageData.results];
      _sort(items);
      state = ConversationListState(
        items: items,
        isLoading: false,
        page: 1,
        total: pageData.total,
        hasMore: items.length < pageData.total,
        query: q,
        filter: state.filter,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final repo = await _repo;
      final pageData = await repo.listPage(
        page: nextPage,
        pageSize: _pageSize,
        status: state.statusParam,
        query: state.query.isEmpty ? null : state.query,
      );
      final merged = [...state.items, ...pageData.results];
      final seen = <String>{};
      final unique = <Conversation>[];
      for (final c in merged) {
        if (seen.add(c.publicID)) unique.add(c);
      }
      _sort(unique);
      state = state.copyWith(
        items: unique,
        isLoadingMore: false,
        page: nextPage,
        total: pageData.total,
        hasMore: unique.length < pageData.total,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<Conversation?> createNew({String? title, String? model}) async {
    try {
      final repo = await _repo;
      final created = await repo.create(title: title, model: model);
      // New chats are active — show active list after create.
      if (state.filter != ConversationFilter.active) {
        state = state.copyWith(filter: ConversationFilter.active);
      }
      await refresh();
      return created;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> delete(String publicId) async {
    try {
      final repo = await _repo;
      await repo.delete(publicId);
      state = state.copyWith(
        items: state.items.where((c) => c.publicID != publicId).toList(),
        total: (state.total - 1).clamp(0, 1 << 30),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> rename(String publicId, String title) async {
    try {
      final repo = await _repo;
      final updated = await repo.rename(publicId, title);
      state = state.copyWith(
        items: state.items
            .map((c) => c.publicID == publicId ? updated : c)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> toggleStar(String publicId) async {
    final current = state.items
        .where((c) => c.publicID == publicId)
        .firstOrNull;
    if (current == null) return;
    try {
      final repo = await _repo;
      final updated = await repo.setStarred(publicId, !current.isStarred);
      final items = state.items
          .map((c) => c.publicID == publicId ? updated : c)
          .toList();
      _sort(items);
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Archive or unarchive. Removes item from current filter list.
  Future<void> archive(String publicId, {required bool archived}) async {
    try {
      final repo = await _repo;
      await repo.setArchived(publicId, archived);
      state = state.copyWith(
        items: state.items.where((c) => c.publicID != publicId).toList(),
        total: (state.total - 1).clamp(0, 1 << 30),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> createShareLink(String publicId, String webBase) async {
    try {
      final repo = await _repo;
      final share = await repo.createShare(publicId);
      return share.publicUrl(webBase);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> revokeShare(String publicId) async {
    try {
      final repo = await _repo;
      await repo.revokeShare(publicId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final conversationListProvider =
    NotifierProvider<ConversationListController, ConversationListState>(
      ConversationListController.new,
    );
