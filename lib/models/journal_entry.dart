import 'package:flutter/foundation.dart';
import 'frontmatter.dart';

/// Represents a single journal entry backed by a .md file.
@immutable
class JournalEntry {
  final String filePath;
  final DateTime date;
  final Frontmatter frontmatter;
  final String body;
  final DateTime lastModified;

  const JournalEntry({
    required this.filePath,
    required this.date,
    required this.frontmatter,
    required this.body,
    required this.lastModified,
  });

  String get title {
    final firstLine = body.trimLeft().split('\n').first.trim();
    if (firstLine.startsWith('#')) {
      return firstLine.replaceFirst(RegExp(r'^#+\s*'), '');
    }
    return firstLine.length > 60 ? '${firstLine.substring(0, 60)}...' : firstLine;
  }

  int get wordCount => body.trim().isEmpty ? 0 : body.trim().split(RegExp(r'\s+')).length;

  JournalEntry copyWith({
    String? filePath,
    DateTime? date,
    Frontmatter? frontmatter,
    String? body,
    DateTime? lastModified,
  }) {
    return JournalEntry(
      filePath: filePath ?? this.filePath,
      date: date ?? this.date,
      frontmatter: frontmatter ?? this.frontmatter,
      body: body ?? this.body,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntry &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          date == other.date &&
          frontmatter == other.frontmatter &&
          body == other.body;

  @override
  int get hashCode => Object.hash(filePath, date, frontmatter, body);
}
