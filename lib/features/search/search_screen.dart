import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/search/search_provider.dart';
import '../../db/search_database.dart';

/// Full-text search screen backed by the FTS5 index.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      ref.read(searchProvider.notifier).clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchProvider.notifier).search(value);
    });
  }

  void _clearQuery() {
    _controller.clear();
    ref.read(searchProvider.notifier).clear();
    setState(() {});
  }

  void _openEntry(DateTime date) {
    final iso = '${date.year.toString().padLeft(4, '0')}'
        '-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';
    context.go('/daily?date=$iso');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reindex = ref.watch(reindexProvider);
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSearch)),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _controller,
              autofocus: false,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearQuery,
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                setState(() {});
                _onQueryChanged(v);
              },
            ),
          ),

          // Index status chip
          reindex.when(
            data: (n) => _StatusBar(
              message: n > 0
                  ? l10n.searchIndexUpdated(n)
                  : l10n.searchIndexReady,
            ),
            loading: () => _StatusBar(message: l10n.searchIndexing),
            error: (_, _) => const SizedBox.shrink(),
          ),

          const Divider(height: 1),

          // Results
          Expanded(
            child: searchState.when(
              data: (state) {
                if (state.query.isEmpty) {
                  return _EmptyHint(l10n: l10n);
                }
                if (state.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.results.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.searchNoResults,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  );
                }
                return _ResultsList(
                  results: state.results,
                  onTap: _openEntry,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatusBar extends StatelessWidget {
  final String message;
  const _StatusBar({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyHint({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.searchHint,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<SearchResult> results;
  final void Function(DateTime date) onTap;

  const _ResultsList({required this.results, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, i) {
        final r = results[i];
        final dateStr = DateFormat.yMMMd(locale).format(r.date);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
            foregroundColor:
                Theme.of(context).colorScheme.onPrimaryContainer,
            child: Text(
              r.date.day.toString(),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            r.title.isNotEmpty ? r.title : dateStr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              if (r.snippet.isNotEmpty)
                Text(
                  r.snippet,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
          isThreeLine: r.snippet.isNotEmpty,
          onTap: () => onTap(r.date),
        );
      },
    );
  }
}
