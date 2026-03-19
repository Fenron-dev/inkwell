import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/search_database.dart';
import '../vault/vault_provider.dart';
import 'search_index.dart';

// ---------------------------------------------------------------------------
// SearchIndex provider
// ---------------------------------------------------------------------------

/// Provides the [SearchIndex] for the currently open vault.
///
/// Returns null when no vault is loaded. Disposes (closes the DB connection)
/// whenever the vault changes.
final searchIndexProvider = Provider<SearchIndex?>((ref) {
  final vault = ref.watch(vaultProvider).valueOrNull;
  if (vault == null) return null;

  final index = SearchIndex(vault.indexDbPath);
  ref.onDispose(() => index.close());
  return index;
});

// ---------------------------------------------------------------------------
// Background reindex
// ---------------------------------------------------------------------------

/// Triggers an incremental reindex whenever the vault becomes available.
///
/// The returned value is the number of entries that were indexed or updated.
/// Watch this provider in the search screen to show indexing status.
final reindexProvider = FutureProvider<int>((ref) async {
  final vault = ref.watch(vaultProvider).valueOrNull;
  if (vault == null) return 0;

  final index = ref.watch(searchIndexProvider);
  if (index == null) return 0;

  return index.reindex(vault);
});

// ---------------------------------------------------------------------------
// Search state
// ---------------------------------------------------------------------------

/// Immutable state for the search screen.
class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isSearching;
  final List<String> selectedTags;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.selectedTags = const [],
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isSearching,
    List<String>? selectedTags,
  }) =>
      SearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        isSearching: isSearching ?? this.isSearching,
        selectedTags: selectedTags ?? this.selectedTags,
      );
}

class SearchNotifier extends AsyncNotifier<SearchState> {
  @override
  Future<SearchState> build() async => const SearchState();

  Future<void> search(String query) async {
    final tags = state.valueOrNull?.selectedTags ?? const [];
    if (query.trim().isEmpty) {
      if (tags.isEmpty) {
        state = AsyncData((state.valueOrNull ?? const SearchState())
            .copyWith(query: '', results: [], isSearching: false));
        return;
      }
      // No text but tags selected → filter by tags only.
      await _runTagFilter(tags);
      return;
    }

    state = AsyncData(
      (state.valueOrNull ?? const SearchState())
          .copyWith(query: query, isSearching: true),
    );

    try {
      final index = ref.read(searchIndexProvider);
      if (index == null) {
        state = AsyncData(SearchState(query: query, selectedTags: tags));
        return;
      }
      final results = await index.search(query, tagFilter: tags);
      state = AsyncData(SearchState(
          query: query, results: results, selectedTags: tags));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Toggles [tag] in the selected tags and re-runs the current search.
  Future<void> toggleTag(String tag) async {
    final current = state.valueOrNull ?? const SearchState();
    final tags = List<String>.from(current.selectedTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = AsyncData(current.copyWith(selectedTags: tags, isSearching: true));
    await _applyCurrentFilter(current.query, tags);
  }

  Future<void> _applyCurrentFilter(String query, List<String> tags) async {
    try {
      final index = ref.read(searchIndexProvider);
      if (index == null) {
        state = AsyncData(SearchState(query: query, selectedTags: tags));
        return;
      }
      final List<SearchResult> results;
      if (query.trim().isNotEmpty) {
        results = await index.search(query, tagFilter: tags);
      } else if (tags.isNotEmpty) {
        results = await index.filterByTags(tags);
      } else {
        results = const [];
      }
      state = AsyncData(SearchState(
          query: query, results: results, selectedTags: tags));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _runTagFilter(List<String> tags) async {
    state = AsyncData(
      (state.valueOrNull ?? const SearchState())
          .copyWith(isSearching: true, selectedTags: tags),
    );
    await _applyCurrentFilter('', tags);
  }

  void clear() {
    state = const AsyncData(SearchState());
  }
}

/// All distinct tags in the search index, sorted alphabetically.
final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final index = ref.watch(searchIndexProvider);
  if (index == null) return const [];
  return index.getAllTags();
});

final searchProvider =
    AsyncNotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
