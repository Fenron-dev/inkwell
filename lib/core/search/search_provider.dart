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

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isSearching,
  }) =>
      SearchState(
        query: query ?? this.query,
        results: results ?? this.results,
        isSearching: isSearching ?? this.isSearching,
      );
}

class SearchNotifier extends AsyncNotifier<SearchState> {
  @override
  Future<SearchState> build() async => const SearchState();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncData(SearchState());
      return;
    }

    // Show spinner while searching
    state = AsyncData(
      (state.valueOrNull ?? const SearchState())
          .copyWith(query: query, isSearching: true),
    );

    try {
      final index = ref.read(searchIndexProvider);
      if (index == null) {
        state = AsyncData(SearchState(query: query));
        return;
      }
      final results = await index.search(query);
      state = AsyncData(SearchState(query: query, results: results));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void clear() => state = const AsyncData(SearchState());
}

final searchProvider =
    AsyncNotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
