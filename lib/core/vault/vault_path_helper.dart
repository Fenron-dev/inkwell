import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Returns a sensible, always-writable default vault path per platform.
///
/// Android: external app files dir (`/sdcard/Android/data/{id}/files/Inkwell`)
///   → writable without permissions, accessible via USB / file manager
/// iOS:     app Documents dir → accessible via Files app
/// Desktop: app documents dir (user can move the vault later via settings)
class VaultPathHelper {
  static Future<String> defaultVaultPath() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // getExternalStorageDirectory() = /sdcard/Android/data/<id>/files/
      // Always writable, no special permissions needed, accessible via USB.
      final external = await getExternalStorageDirectory();
      if (external != null) {
        return p.join(external.path, 'Inkwell');
      }
      // Fallback to internal if external is unavailable
      final docs = await getApplicationDocumentsDirectory();
      return p.join(docs.path, 'Inkwell');
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // App Documents dir — visible in iOS Files app
      final docs = await getApplicationDocumentsDirectory();
      return p.join(docs.path, 'Inkwell');
    }

    // Desktop: use OS documents folder
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'Inkwell');
  }

  /// True on platforms where the user can freely pick any directory.
  static bool get canPickDirectory =>
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}
