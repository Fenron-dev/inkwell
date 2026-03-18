import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../../core/vault/vault_provider.dart';
import '../editor/editor_screen.dart';

/// Daily notes view with day navigation and editor.
class DailyNotesScreen extends ConsumerStatefulWidget {
  const DailyNotesScreen({super.key});

  @override
  ConsumerState<DailyNotesScreen> createState() => _DailyNotesScreenState();
}

class _DailyNotesScreenState extends ConsumerState<DailyNotesScreen> {
  DateTime _selectedDate = DateTime.now();

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
