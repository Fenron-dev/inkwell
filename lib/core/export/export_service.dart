import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/vault_config.dart';

/// Result of a ZIP export operation.
class ExportResult {
  /// Absolute path of the saved ZIP file.
  final String path;

  const ExportResult(this.path);
}

/// Service that bundles a vault into a ZIP archive and saves it to disk.
class ExportService {
  /// Exports [vault] as a ZIP file.
  ///
  /// On desktop platforms the user is shown a save-file dialog.
  /// On mobile the ZIP is written to the app's documents directory so it
  /// is accessible via the system file manager / Files app.
  ///
  /// Returns an [ExportResult] with the final file path, or null when the
  /// user cancelled the desktop save dialog.
  Future<ExportResult?> export(VaultConfig vault) async {
    final zipBytes = await compute(_buildZip, vault.path);

    final fileName =
        'inkwell_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.zip';

    if (_isDesktop) {
      // Let the user choose where to save.
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Vault als ZIP speichern',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (savePath == null) return null;

      await File(savePath).writeAsBytes(zipBytes);
      return ExportResult(savePath);
    } else {
      // Mobile: write to the app's documents directory.
      final dir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory(p.join(dir.path, 'exports'));
      await exportsDir.create(recursive: true);

      final file = File(p.join(exportsDir.path, fileName));
      await file.writeAsBytes(zipBytes);
      return ExportResult(file.path);
    }
  }

  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}

// ---------------------------------------------------------------------------
// Compute isolate — keeps the main thread free while zipping
// ---------------------------------------------------------------------------

/// Builds a ZIP archive from the vault directory and returns its bytes.
/// Runs on a background isolate via [compute].
///
/// Included directories: journal/, _templates/, _attachments/
/// The .inkwell/ metadata folder (index.db etc.) is excluded.
List<int> _buildZip(String vaultPath) {
  final archive = Archive();
  final includedDirs = ['journal', '_templates', '_attachments'];

  for (final dirName in includedDirs) {
    final dir = Directory(p.join(vaultPath, dirName));
    if (!dir.existsSync()) continue;
    _addDirectory(archive, dir, '$dirName/');
  }

  // Also include settings.json so the vault can be re-imported.
  final settings =
      File(p.join(vaultPath, '.inkwell', 'settings.json'));
  if (settings.existsSync()) {
    final bytes = settings.readAsBytesSync();
    archive.addFile(
        ArchiveFile('.inkwell/settings.json', bytes.length, bytes));
  }

  return ZipEncoder().encode(archive)!;
}

void _addDirectory(Archive archive, Directory dir, String prefix) {
  for (final entity in dir.listSync(recursive: false)) {
    if (entity is File) {
      final bytes = entity.readAsBytesSync();
      final name = prefix + p.basename(entity.path);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    } else if (entity is Directory) {
      _addDirectory(
        archive,
        entity,
        '$prefix${p.basename(entity.path)}/',
      );
    }
  }
}
