import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../db/search_database.dart';
import '../../models/vault_config.dart';
import '../markdown/frontmatter_parser.dart';

/// Service that builds and maintains the FTS5 search index for a vault.
///
/// The index is stored in `.inkwell/index.db` inside the vault directory.
/// Indexing is incremental: only files whose mtime has changed since the
/// last index run are processed.
class SearchIndex {
  final SearchDatabase _db;

  SearchIndex(String dbPath) : _db = SearchDatabase(dbPath);

  Future<void> close() => _db.close();

  // ---------------------------------------------------------------------------
  // Indexing
  // ---------------------------------------------------------------------------

  /// Scans the vault's journal directory and re-indexes changed files.
  ///
  /// Returns the number of entries that were newly indexed or updated.
  Future<int> reindex(VaultConfig vault) async {
    final journalDir = Directory(vault.journalPath);
    if (!await journalDir.exists()) return 0;

    final indexed = await _db.getAllIndexedMtimes();
    final seen = <String>{};
    int count = 0;

    await for (final yearEntry in journalDir.list()) {
      if (yearEntry is! Directory) continue;

      await for (final fileEntry in yearEntry.list()) {
        if (fileEntry is! File || !fileEntry.path.endsWith('.md')) continue;

        final filePath = fileEntry.path;
        final stat = await fileEntry.stat();
        final mtime = stat.modified.millisecondsSinceEpoch;
        seen.add(filePath);

        // Skip files that are already indexed at the same mtime.
        if (indexed[filePath] == mtime) continue;

        await _indexFile(fileEntry, filePath, mtime);
        count++;
      }
    }

    // Remove index entries for files that no longer exist.
    for (final filePath in indexed.keys) {
      if (!seen.contains(filePath)) {
        await _db.removeEntry(filePath);
      }
    }

    return count;
  }

  /// Updates the index for a single entry (called after writing an entry).
  Future<void> indexEntry(String filePath, DateTime date) async {
    final file = File(filePath);
    if (!await file.exists()) {
      await _db.removeEntry(filePath);
      return;
    }
    final stat = await file.stat();
    await _indexFile(file, filePath, stat.modified.millisecondsSinceEpoch,
        hintDate: date);
  }

  Future<void> removeEntry(String filePath) => _db.removeEntry(filePath);

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  Future<List<SearchResult>> search(String query) => _db.search(query);

  Future<int> countEntries() => _db.countEntries();

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<void> _indexFile(
    File file,
    String filePath,
    int mtime, {
    DateTime? hintDate,
  }) async {
    final raw = await file.readAsString();
    final (frontmatter, body) = FrontmatterParser.parse(raw);

    final fileName = p.basenameWithoutExtension(filePath);
    final date = hintDate ?? DateTime.tryParse(fileName);
    if (date == null) return; // Not a date-named file — skip.

    await _db.upsertEntry(
      filePath: filePath,
      date: '${date.year.toString().padLeft(4, '0')}'
          '-${date.month.toString().padLeft(2, '0')}'
          '-${date.day.toString().padLeft(2, '0')}',
      title: _extractTitle(body, fileName),
      body: body,
      mood: frontmatter.mood?.toString(),
      energy: frontmatter.energy?.toString(),
      tags: jsonEncode(frontmatter.tags),
      wordCount:
          body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
      lastIndexedMtime: mtime,
    );
  }

  /// Extracts a display title from the entry body.
  ///
  /// Returns the first `# Heading` found, falling back to the first
  /// non-empty line, and finally the ISO date [fallback].
  static String _extractTitle(String body, String fallback) {
    for (final line in body.split('\n')) {
      final t = line.trim();
      if (t.startsWith('# ')) return t.substring(2).trim();
      if (t.isNotEmpty && !t.startsWith('#')) return t;
    }
    return fallback;
  }
}
