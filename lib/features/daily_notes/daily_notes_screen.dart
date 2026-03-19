import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/search/search_provider.dart';
import '../../core/vault/vault_provider.dart';
import '../editor/editor_screen.dart';

/// Daily notes view with day navigation and editor.
class DailyNotesScreen extends ConsumerStatefulWidget {
  /// When set (e.g. navigated from search results), the screen opens on this
  /// date instead of today.
  final DateTime? initialDate;

  const DailyNotesScreen({super.key, this.initialDate});

  @override
  ConsumerState<DailyNotesScreen> createState() => _DailyNotesScreenState();
}

class _DailyNotesScreenState extends ConsumerState<DailyNotesScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void didUpdateWidget(DailyNotesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != null &&
        widget.initialDate != oldWidget.initialDate) {
      setState(() => _selectedDate = widget.initialDate!);
    }
  }

  void _goToDay(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _deleteEntry(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteEntryTitle),
        content: Text(l10n.deleteEntryHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final vault = ref.read(vaultProvider).valueOrNull;
    if (vault == null) return;

    final service = ref.read(vaultServiceProvider);
    final filePath = service.entryPath(vault, _selectedDate);
    await service.deleteEntry(vault, _selectedDate);

    // Remove from search index (fire-and-forget).
    ref.read(searchIndexProvider)?.removeEntry(filePath);

    if (mounted) _goToToday();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vault = ref.watch(vaultProvider);
    final dateStr = DateFormat.yMMMMEEEEd(
      Localizations.localeOf(context).languageCode,
    ).format(_selectedDate);

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr),
        actions: [
          if (!isToday)
            TextButton(
              onPressed: _goToToday,
              child: Text(l10n.calendarToday),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deleteEntryTooltip,
            onPressed: () => _deleteEntry(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Day navigation bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _goToDay(-1),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _goToDay(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Editor area
          Expanded(
            child: vault.when(
              data: (config) {
                if (config == null) {
                  return Center(
                    child: Text(l10n.vaultChooseLocation),
                  );
                }
                return EditorScreen(
                  key: ValueKey(_selectedDate),
                  date: _selectedDate,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
