import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../models/journal_entry.dart';
import '../../models/vault_config.dart';
import '../markdown/frontmatter_parser.dart';

/// Service for all vault file system operations.
///
/// The vault directory is the source of truth. All entries are .md files
/// with YAML frontmatter, stored in journal/YYYY/ subdirectories.
class VaultService {
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static const _defaultTemplate = '''---
mood:
energy:
sleep:
tags: []
---

# {date}

''';

  /// Creates a new vault at the given path with the standard directory structure.
  Future<VaultConfig> createVault(String path, String name) async {
    final config = VaultConfig(
      path: path,
      name: name,
      createdAt: DateTime.now(),
    );

    await Directory(config.journalPath).create(recursive: true);
    await Directory(config.templatesPath).create(recursive: true);
    await Directory(config.attachmentsPath).create(recursive: true);
    await Directory(config.inkwellPath).create(recursive: true);

    // Write default daily template
    final templateFile = File('${config.templatesPath}/daily.md');
    await templateFile.writeAsString(_defaultTemplate);

    // Write vault config
    final configFile = File('${config.inkwellPath}/settings.json');
    await configFile.writeAsString(jsonEncode(config.toJson()));

    return config;
  }

  /// Opens an existing vault from its path.
  /// Returns null if the path doesn't exist or is not accessible.
  Future<VaultConfig?> openVault(String path) async {
    try {
      final configFile = File('$path/.inkwell/settings.json');
      if (await configFile.exists()) {
        final json = jsonDecode(await configFile.readAsString());
        return VaultConfig.fromJson(json as Map<String, dynamic>);
      }

      // Adopt an existing folder as a vault (e.g. an Obsidian vault)
      final dir = Directory(path);
      if (await dir.exists()) {
        final config = VaultConfig(
          path: path,
          name: p.basename(path),
          createdAt: DateTime.now(),
        );
        await Directory(config.inkwellPath).create(recursive: true);
        final settingsFile = File('${config.inkwellPath}/settings.json');
        await settingsFile.writeAsString(jsonEncode(config.toJson()));
        return config;
      }
    } catch (_) {
      // Path not accessible or not writable — return null so the caller
      // can clear the saved path and show the setup screen.
      return null;
    }

    return null;
  }

  static final _monthFolderFormat = DateFormat('MM - MMMM', 'en_US');

  /// Returns the file path for a given date's entry.
  ///
  /// Structure: `journal/YYYY/MM - Month/YYYY-MM-DD.md`
  String entryPath(VaultConfig vault, DateTime date) {
    final year = date.year.toString();
    final month = _monthFolderFormat.format(date);
    final fileName = '${_dateFormat.format(date)}.md';
    return p.join(vault.journalPath, year, month, fileName);
  }

  /// Reads a journal entry for a specific date. Returns null if no entry exists.
  Future<JournalEntry?> readEntry(VaultConfig vault, DateTime date) async {
    final path = entryPath(vault, date);
    final file = File(path);

    if (!await file.exists()) return null;

    final raw = await file.readAsString();
    final stat = await file.stat();
    final (frontmatter, body) = FrontmatterParser.parse(raw);

    return JournalEntry(
      filePath: path,
      date: date,
      frontmatter: frontmatter,
      body: body,
      lastModified: stat.modified,
    );
  }

  /// Writes a journal entry. Creates the year directory if needed.
  Future<void> writeEntry(VaultConfig vault, JournalEntry entry) async {
    final path = entryPath(vault, entry.date);
    final dir = Directory(p.dirname(path));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final raw = FrontmatterParser.serialize(entry.frontmatter, entry.body);
    await File(path).writeAsString(raw);
  }

  /// Creates a new entry from the daily template for the given date.
  Future<JournalEntry> createEntryFromTemplate(
    VaultConfig vault,
    DateTime date,
  ) async {
    final templateFile = File('${vault.templatesPath}/daily.md');
    String templateContent = _defaultTemplate;

    if (await templateFile.exists()) {
      templateContent = await templateFile.readAsString();
    }

    final dateStr = _dateFormat.format(date);
    final content = templateContent.replaceAll('{date}', dateStr);
    final (frontmatter, body) = FrontmatterParser.parse(content);

    final entry = JournalEntry(
      filePath: entryPath(vault, date),
      date: date,
      frontmatter: frontmatter,
      body: body,
      lastModified: DateTime.now(),
    );

    await writeEntry(vault, entry);
    return entry;
  }

  /// Lists all entry dates in the vault by scanning the journal directory.
  Future<List<DateTime>> listEntryDates(VaultConfig vault) async {
    final journalDir = Directory(vault.journalPath);
    if (!await journalDir.exists()) return [];

    final dates = <DateTime>[];

    await for (final yearDir in journalDir.list()) {
      if (yearDir is! Directory) continue;

      await for (final monthDir in yearDir.list()) {
        if (monthDir is! Directory) continue;

        await for (final file in monthDir.list()) {
          if (file is! File || !file.path.endsWith('.md')) continue;

          final fileName = p.basenameWithoutExtension(file.path);
          final date = DateTime.tryParse(fileName);
          if (date != null) dates.add(date);
        }
      }
    }

    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  /// Deletes a journal entry.
  Future<void> deleteEntry(VaultConfig vault, DateTime date) async {
    final file = File(entryPath(vault, date));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Reads the daily template content.
  Future<String> readTemplate(VaultConfig vault) async {
    final file = File('${vault.templatesPath}/daily.md');
    if (await file.exists()) {
      return file.readAsString();
    }
    return _defaultTemplate;
  }
}
