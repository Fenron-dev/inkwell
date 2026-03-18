import 'package:flutter/foundation.dart';

/// Typed representation of YAML frontmatter in a journal entry.
@immutable
class Frontmatter {
  final int? mood;
  final int? energy;
  final double? sleep;
  final String? location;
  final List<String> tags;
  final Duration? writingDuration;
  final int? wordCount;

  /// Preserves unknown fields from other tools (e.g. Obsidian plugins).
  final Map<String, dynamic> extra;

  const Frontmatter({
    this.mood,
    this.energy,
    this.sleep,
    this.location,
    this.tags = const [],
    this.writingDuration,
    this.wordCount,
    this.extra = const {},
  });

  Frontmatter copyWith({
    int? mood,
    int? energy,
    double? sleep,
    String? location,
    List<String>? tags,
    Duration? writingDuration,
    int? wordCount,
    Map<String, dynamic>? extra,
  }) {
    return Frontmatter(
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      sleep: sleep ?? this.sleep,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      writingDuration: writingDuration ?? this.writingDuration,
      wordCount: wordCount ?? this.wordCount,
      extra: extra ?? this.extra,
    );
  }

  bool get isEmpty =>
      mood == null &&
      energy == null &&
      sleep == null &&
      location == null &&
      tags.isEmpty &&
      writingDuration == null &&
      wordCount == null &&
      extra.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Frontmatter &&
          runtimeType == other.runtimeType &&
          mood == other.mood &&
          energy == other.energy &&
          sleep == other.sleep &&
          location == other.location &&
          listEquals(tags, other.tags) &&
          writingDuration == other.writingDuration &&
          wordCount == other.wordCount &&
          mapEquals(extra, other.extra);

  @override
  int get hashCode => Object.hash(
        mood,
        energy,
        sleep,
        location,
        Object.hashAll(tags),
        writingDuration,
        wordCount,
        Object.hashAll(extra.entries),
      );
}
