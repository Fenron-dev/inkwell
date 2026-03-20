import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Result of a ZIP import operation.
class ImportResult {
  /// Absolute path of the vault directory that was extracted.
  final String vaultPath;
  const ImportResult(this.vaultPath);
}

/// Extracts an Inkwell ZIP backup and returns the vault directory path.
class ImportService {
  /// Picks a ZIP file and extracts it to a vault directory.
  ///
  /// On desktop: asks the user for a destination folder, extracts there.
  /// On mobile: extracts to `<documents>/inkwell_import_<date>`.
  ///
  /// Returns [ImportResult] with the vault path, or null if the user cancelled.
  Future<ImportResult?> importZip() async {
    // Step 1 — pick the ZIP file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Inkwell ZIP auswählen',
    );
    if (result == null || result.files.isEmpty) return null;
    final zipPath = result.files.first.path;
    if (zipPath == null) return null;

    // Step 2 — determine destination directory
    final String destDir;
    if (_isDesktop) {
      final picked = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Zielordner für den Import wählen',
      );
      if (picked == null) return null;
      destDir = picked;
    } else {
      final docs = await getApplicationDocumentsDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      destDir = p.join(docs.path, 'inkwell_import_$stamp');
    }

    // Step 3 — extract in background isolate
    await compute(_extractZip, _ExtractArgs(zipPath, destDir));

    return ImportResult(destDir);
  }

  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}

class _ExtractArgs {
  final String zipPath;
  final String destDir;
  const _ExtractArgs(this.zipPath, this.destDir);
}

void _extractZip(_ExtractArgs args) {
  final bytes = File(args.zipPath).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final dest = Directory(args.destDir);
  if (!dest.existsSync()) dest.createSync(recursive: true);

  for (final file in archive) {
    final outPath = p.join(args.destDir, file.name);
    if (file.isFile) {
      final outFile = File(outPath);
      outFile.parent.createSync(recursive: true);
      outFile.writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(outPath).createSync(recursive: true);
    }
  }
}
