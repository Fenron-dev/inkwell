import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import '../../models/frontmatter.dart';

/// Parses and serializes YAML frontmatter from/to Markdown files.
///
/// Key design rule: unknown fields are preserved on roundtrip to maintain
/// compatibility with Obsidian and other tools.
class FrontmatterParser {
  static final _frontmatterRegex = RegExp(
    r'^---\s*\n([\s\S]*?)\n---\s*\n?',
  );

  /// Parses a raw markdown string into (Frontmatter, body) tuple.
  static (Frontmatter, String) parse(String raw) {
    final match = _frontmatterRegex.firstMatch(raw);
    if (match == null) {
      return (const Frontmatter(), raw);
    }

    final yamlString = match.group(1)!;
    final body = raw.substring(match.end);

    try {
      final yamlMap = loadYaml(yamlString);
      if (yamlMap is! YamlMap) {
        return (const Frontmatter(), body);
      }

      final data = Map<String, dynamic>.from(yamlMap.value);
      final frontmatter = _fromMap(data);
      return (frontmatter, body);
    } catch (_) {
      return (const Frontmatter(), body);
    }
  }

  /// Serializes a Frontmatter + body back into a full markdown string.
  /// Preserves unknown fields in the `extra` map.
  static String serialize(Frontmatter fm, String body) {
    if (fm.isEmpty) return body;

    final data = _toMap(fm);
    final writer = YamlWriter();
    final yamlString = writer.write(data);

    return '---\n$yamlString\n---\n$body';
  }

  static Frontmatter _fromMap(Map<String, dynamic> data) {
    final known = <String>{
      'mood',
      'energy',
      'sleep',
      'location',
      'tags',
      'writing_duration',
      'word_count',
    };

    final extra = Map<String, dynamic>.from(data)
      ..removeWhere((key, _) => known.contains(key));

    return Frontmatter(
      mood: _asInt(data['mood']),
      energy: _asInt(data['energy']),
      sleep: _asDouble(data['sleep']),
      location: data['location'] as String?,
      tags: _asTags(data['tags']),
      writingDuration: _asDuration(data['writing_duration']),
      wordCount: _asInt(data['word_count']),
      extra: extra,
    );
  }

  static Map<String, dynamic> _toMap(Frontmatter fm) {
    final data = <String, dynamic>{};

    if (fm.mood != null) data['mood'] = fm.mood;
    if (fm.energy != null) data['energy'] = fm.energy;
    if (fm.sleep != null) data['sleep'] = fm.sleep;
    if (fm.location != null) data['location'] = fm.location;
    if (fm.tags.isNotEmpty) data['tags'] = fm.tags;
    if (fm.writingDuration != null) {
      data['writing_duration'] = _durationToString(fm.writingDuration!);
    }
    if (fm.wordCount != null) data['word_count'] = fm.wordCount;

    // Append unknown fields at the end
    data.addAll(fm.extra);

    return data;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String> _asTags(dynamic value) {
    if (value is YamlList) return value.map((e) => e.toString()).toList();
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  static Duration? _asDuration(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    final match = RegExp(r'^(\d+)([hms])$').firstMatch(str);
    if (match == null) return null;
    final amount = int.parse(match.group(1)!);
    return switch (match.group(2)!) {
      'h' => Duration(hours: amount),
      'm' => Duration(minutes: amount),
      's' => Duration(seconds: amount),
      _ => null,
    };
  }

  static String _durationToString(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }
}
