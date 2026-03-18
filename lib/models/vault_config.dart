import 'package:flutter/foundation.dart';

/// Configuration for the currently opened vault.
@immutable
class VaultConfig {
  final String path;
  final String name;
  final DateTime createdAt;

  const VaultConfig({
    required this.path,
    required this.name,
    required this.createdAt,
  });

  String get journalPath => '$path/journal';
  String get templatesPath => '$path/_templates';
  String get attachmentsPath => '$path/_attachments';
  String get inkwellPath => '$path/.inkwell';
  String get indexDbPath => '$inkwellPath/index.db';

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VaultConfig.fromJson(Map<String, dynamic> json) => VaultConfig(
        path: json['path'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
