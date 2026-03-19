import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Drift-backed SQLite database for the journal search index.
///
/// Uses a regular `indexed_entries` table plus an FTS5 virtual table
/// (`entry_fts`) kept in sync via triggers. All DDL is managed via raw SQL
/// in [migration], so no `build_runner` / code-generation step is needed.
class SearchDatabase extends GeneratedDatabase {
  SearchDatabase(String dbPath) : super(NativeDatabase(File(dbPath)));

  // No Drift-managed tables — schema is created via customStatement below.
  @override
  Iterable<TableInfo<Table, Object>> get allTables =>
      const <TableInfo<Table, Object>>[];

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      const <DatabaseSchemaEntity>[];

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (_) async {
          await customStatement('''
            CREATE TABLE IF NOT EXISTS indexed_entries (
              file_path TEXT PRIMARY KEY NOT NULL,
              date      TEXT NOT NULL,
              title     TEXT NOT NULL DEFAULT '',
              body      TEXT NOT NULL DEFAULT '',
              mood      TEXT,
              energy    TEXT,
              tags      TEXT NOT NULL DEFAULT '[]',
              word_count         INTEGER NOT NULL DEFAULT 0,
              last_indexed_mtime INTEGER NOT NULL DEFAULT 0
            )
          ''');

          // FTS5 external-content table backed by indexed_entries.
          // Columns: title (0), body (1), tags (2)
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS entry_fts USING fts5(
              title, body, tags,
              content=indexed_entries,
              content_rowid=rowid
            )
          ''');

          // Triggers to keep FTS5 in sync with the content table.
          await customStatement('''
            CREATE TRIGGER entry_fts_ai AFTER INSERT ON indexed_entries BEGIN
              INSERT INTO entry_fts(rowid, title, body, tags)
              VALUES (new.rowid, new.title, new.body, new.tags);
            END
          ''');

          await customStatement('''
            CREATE TRIGGER entry_fts_ad AFTER DELETE ON indexed_entries BEGIN
              INSERT INTO entry_fts(entry_fts, rowid, title, body, tags)
              VALUES ('delete', old.rowid, old.title, old.body, old.tags);
            END
          ''');

          await customStatement('''
            CREATE TRIGGER entry_fts_au AFTER UPDATE ON indexed_entries BEGIN
              INSERT INTO entry_fts(entry_fts, rowid, title, body, tags)
              VALUES ('delete', old.rowid, old.title, old.body, old.tags);
              INSERT INTO entry_fts(rowid, title, body, tags)
              VALUES (new.rowid, new.title, new.body, new.tags);
            END
          ''');
        },
      );

  // ---------------------------------------------------------------------------
  // Write operations
  // ---------------------------------------------------------------------------

  /// Inserts or replaces an indexed entry. Triggers keep FTS5 in sync.
  Future<void> upsertEntry({
    required String filePath,
    required String date,
    required String title,
    required String body,
    String? mood,
    String? energy,
    required String tags,
    required int wordCount,
    required int lastIndexedMtime,
  }) async {
    await customStatement(
      '''
      INSERT OR REPLACE INTO indexed_entries
        (file_path, date, title, body, mood, energy, tags,
         word_count, last_indexed_mtime)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        filePath,
        date,
        title,
        body,
        mood,
        energy,
        tags,
        wordCount,
        lastIndexedMtime,
      ],
    );
  }

  /// Removes an entry from the index (FTS5 delete trigger fires automatically).
  Future<void> removeEntry(String filePath) async {
    await customStatement(
      'DELETE FROM indexed_entries WHERE file_path = ?',
      [filePath],
    );
  }

  // ---------------------------------------------------------------------------
  // Read operations
  // ---------------------------------------------------------------------------

  /// Full-text search with optional tag filter.
  ///
  /// When [tagFilter] is non-empty only entries that carry ALL of those tags
  /// (AND semantics) are returned.
  Future<List<SearchResult>> search(
    String query, {
    List<String> tagFilter = const [],
    int limit = 50,
  }) async {
    final ftsQuery = _buildFtsQuery(query);
    if (ftsQuery.isEmpty) return const [];

    final tagClause = tagFilter.isEmpty
        ? ''
        : 'AND (SELECT COUNT(*) FROM json_each(ie.tags) jt '
            'WHERE jt.value IN (${List.filled(tagFilter.length, '?').join(',')})) = ${tagFilter.length}';

    final rows = await customSelect(
      '''
      SELECT ie.file_path,
             ie.date,
             ie.title,
             snippet(entry_fts, 1, '[', ']', '…', 24) AS snippet
      FROM entry_fts
      JOIN indexed_entries ie ON ie.rowid = entry_fts.rowid
      WHERE entry_fts MATCH ?
      $tagClause
      ORDER BY rank
      LIMIT ?
      ''',
      variables: [
        Variable.withString(ftsQuery),
        ...tagFilter.map(Variable.withString),
        Variable.withInt(limit),
      ],
      readsFrom: const {},
    ).get();

    return _mapResults(rows);
  }

  /// Returns all entries that carry ALL of [tags], sorted by date descending.
  ///
  /// Used for browsing by tag when no text query is entered.
  Future<List<SearchResult>> filterByTags(
    List<String> tags, {
    int limit = 200,
  }) async {
    if (tags.isEmpty) return const [];

    final rows = await customSelect(
      '''
      SELECT file_path, date, title, '' AS snippet
      FROM indexed_entries
      WHERE (SELECT COUNT(*) FROM json_each(tags) jt
             WHERE jt.value IN (${List.filled(tags.length, '?').join(',')})) = ${tags.length}
      ORDER BY date DESC
      LIMIT ?
      ''',
      variables: [
        ...tags.map(Variable.withString),
        Variable.withInt(limit),
      ],
      readsFrom: const {},
    ).get();

    return _mapResults(rows);
  }

  /// Returns a sorted list of all distinct tag values in the index.
  Future<List<String>> getAllTags() async {
    final rows = await customSelect(
      '''
      SELECT DISTINCT jt.value AS tag
      FROM indexed_entries, json_each(tags) jt
      WHERE jt.value != ''
      ORDER BY jt.value
      ''',
    ).get();
    return rows.map((r) => r.read<String>('tag')).toList();
  }

  static List<SearchResult> _mapResults(List<QueryRow> rows) => rows
      .map((row) => SearchResult(
            filePath: row.read<String>('file_path'),
            date: DateTime.parse(row.read<String>('date')),
            title: row.read<String>('title'),
            snippet: row.read<String>('snippet'),
          ))
      .toList();

  /// Returns a map of `filePath → lastIndexedMtime` for all indexed entries.
  Future<Map<String, int>> getAllIndexedMtimes() async {
    final rows = await customSelect(
      'SELECT file_path, last_indexed_mtime FROM indexed_entries',
    ).get();
    return {
      for (final r in rows)
        r.read<String>('file_path'): r.read<int>('last_indexed_mtime'),
    };
  }

  Future<int> countEntries() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM indexed_entries',
    ).getSingle();
    return row.read<int>('c');
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Converts a plain-text user query into an FTS5 MATCH expression.
  ///
  /// Strips FTS5 special characters, splits into terms, and appends `*`
  /// for prefix matching so "jour" matches "journal".
  static String _buildFtsQuery(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'["\(\)\[\]\{\}\^\$\*\?\+\|\\<>]'), ' ')
        .trim();
    if (cleaned.isEmpty) return '';
    return cleaned
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '$t*')
        .join(' ');
  }
}

/// A single row returned by [SearchDatabase.search].
class SearchResult {
  final String filePath;
  final DateTime date;
  final String title;
  final String snippet;

  const SearchResult({
    required this.filePath,
    required this.date,
    required this.title,
    required this.snippet,
  });
}
