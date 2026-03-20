import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/search/search_provider.dart';
import '../../core/vault/entry_refresh_provider.dart';
import '../../core/vault/vault_provider.dart';
import '../../models/journal_entry.dart';
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
  List<JournalEntry> _memories = [];
  bool _memoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMemories());
  }

  @override
  void didUpdateWidget(DailyNotesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != null &&
        widget.initialDate != oldWidget.initialDate) {
      setState(() {
        _selectedDate = widget.initialDate!;
        _memoriesLoaded = false;
        _memories = [];
      });
      _loadMemories();
    }
  }

  Future<void> _loadMemories() async {
    final vault = ref.read(vaultProvider).valueOrNull;
    if (vault == null) return;
    final service = ref.read(vaultServiceProvider);
    final entries =
        await service.findEntriesOnThisDay(vault, _selectedDate);
    if (mounted) {
      setState(() {
        _memories = entries;
        _memoriesLoaded = true;
      });
    }
  }

  void _goToDay(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
      _memoriesLoaded = false;
      _memories = [];
    });
    _loadMemories();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _memoriesLoaded = false;
      _memories = [];
    });
    _loadMemories();
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
          // "An diesem Tag" memories banner
          if (_memoriesLoaded && _memories.isNotEmpty)
            _MemoriesBanner(
              memories: _memories,
              currentYear: _selectedDate.year,
              onTap: (date) => setState(() {
                _selectedDate = date;
                _memoriesLoaded = false;
                _memories = [];
                _loadMemories();
              }),
            ),
          // Editor area
          Expanded(
            child: vault.when(
              data: (config) {
                if (config == null) {
                  return Center(
                    child: Text(l10n.vaultChooseLocation),
                  );
                }
                final refresh = ref.watch(entryRefreshProvider);
                return EditorScreen(
                  key: ValueKey('$_selectedDate-$refresh'),
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

// ---------------------------------------------------------------------------
// Memories banner — shows past entries from the same month+day
// ---------------------------------------------------------------------------

class _MemoriesBanner extends StatelessWidget {
  final List<JournalEntry> memories;
  final int currentYear;
  final void Function(DateTime) onTap;

  const _MemoriesBanner({
    required this.memories,
    required this.currentYear,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.secondaryContainer.withAlpha(100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.history, size: 14, color: scheme.secondary),
                const SizedBox(width: 6),
                Text(
                  l10n.onThisDayTitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.secondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: memories.map((entry) {
                final years = currentYear - entry.date.year;
                final label = l10n.onThisDayYearsAgo(years);
                // First non-empty, non-heading line as snippet
                final snippet = entry.body
                    .split('\n')
                    .where((l) =>
                        l.trim().isNotEmpty && !l.trim().startsWith('#'))
                    .take(1)
                    .join();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onTap(entry.date),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.secondary),
                          ),
                          if (snippet.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              snippet,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
        ],
      ),
    );
  }
}
