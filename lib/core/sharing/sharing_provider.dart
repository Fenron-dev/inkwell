import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds an incoming shared URL/text that is waiting to be handled by the UI.
///
/// When non-null, [AdaptiveShell] opens [QuickCaptureDialog] with the value
/// pre-filled, then resets this back to null.
final pendingShareProvider = StateProvider<String?>((ref) => null);
