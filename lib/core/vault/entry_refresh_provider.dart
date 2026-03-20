import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple counter that is incremented whenever today's journal entry is
/// written outside of the active editor (e.g. Quick Capture).
///
/// The DailyNotesScreen watches this value and includes it in the
/// EditorScreen's ValueKey so the editor rebuilds and picks up new content.
final entryRefreshProvider = StateProvider<int>((ref) => 0);
