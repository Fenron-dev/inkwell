import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import 'calendar_provider.dart';

/// Calendar view with month grid and entry heatmap.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // Store only year+month to avoid time-of-day drift.
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _focusedMonth.year == now.year && _focusedMonth.month == now.month;
  }

  void _prevMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      });

  void _goToCurrentMonth() => setState(() {
        final now = DateTime.now();
        _focusedMonth = DateTime(now.year, now.month);
      });

  void _openDay(DateTime date) {
    final iso = '${date.year.toString().padLeft(4, '0')}'
        '-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')}';
    context.go('/daily?date=$iso');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entryDates = ref.watch(entryDatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navCalendar),
        actions: [
          if (!_isCurrentMonth)
            TextButton(
              onPressed: _goToCurrentMonth,
              child: Text(l10n.calendarToday),
            ),
        ],
      ),
      body: entryDates.when(
        data: (dates) => _MonthView(
          focusedMonth: _focusedMonth,
          entryDates: dates,
          onPrevMonth: _prevMonth,
          onNextMonth: _nextMonth,
          onDayTap: _openDay,
          l10n: l10n,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month view
// ---------------------------------------------------------------------------

class _MonthView extends StatelessWidget {
  final DateTime focusedMonth;
  final Set<String> entryDates;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final void Function(DateTime) onDayTap;
  final AppLocalizations l10n;

  const _MonthView({
    required this.focusedMonth,
    required this.entryDates,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final today = DateTime.now();
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;

    // Monday-first calendar (ISO standard, common in Europe).
    // weekday: 1=Mon … 7=Sun → leading empty cells = weekday - 1.
    final leadingEmpty = firstDay.weekday - 1;

    // Short localized weekday labels starting on Monday (ref date: 2024-01-01 is Monday).
    final monday = DateTime(2024, 1, 1);
    final weekdayLabels = List.generate(
      7,
      (i) => DateFormat.E(locale).format(monday.add(Duration(days: i))),
    );

    // Count entries in the focused month for the summary line.
    final monthPrefix =
        '${focusedMonth.year.toString().padLeft(4, '0')}'
        '-${focusedMonth.month.toString().padLeft(2, '0')}';
    final entriesThisMonth =
        entryDates.where((d) => d.startsWith(monthPrefix)).length;

    return Column(
      children: [
        // Month navigation header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPrevMonth,
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(locale).format(focusedMonth),
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNextMonth,
              ),
            ],
          ),
        ),

        // Weekday header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: 4),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // Calendar grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 0,
            ),
            itemCount: leadingEmpty + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) return const SizedBox.shrink();

              final day = index - leadingEmpty + 1;
              final date = DateTime(focusedMonth.year, focusedMonth.month, day);
              final isoDate =
                  '${date.year.toString().padLeft(4, '0')}'
                  '-${date.month.toString().padLeft(2, '0')}'
                  '-${date.day.toString().padLeft(2, '0')}';
              final hasEntry = entryDates.contains(isoDate);
              final isToday = DateUtils.isSameDay(date, today);

              return _DayCell(
                day: day,
                hasEntry: hasEntry,
                isToday: isToday,
                onTap: () => onDayTap(date),
              );
            },
          ),
        ),

        // Entry count summary
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            l10n.calendarEntries(entriesThisMonth),
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Day cell
// ---------------------------------------------------------------------------

class _DayCell extends StatelessWidget {
  final int day;
  final bool hasEntry;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.hasEntry,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color? bgColor;
    Color textColor;
    BoxBorder? border;

    if (hasEntry && isToday) {
      bgColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
      border = Border.all(color: colorScheme.primary, width: 2);
    } else if (hasEntry) {
      bgColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
    } else if (isToday) {
      bgColor = null;
      textColor = colorScheme.primary;
      border = Border.all(color: colorScheme.primary, width: 1.5);
    } else {
      bgColor = null;
      textColor = colorScheme.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: border,
          ),
          alignment: Alignment.center,
          child: Text(
            day.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  (hasEntry || isToday) ? FontWeight.w600 : FontWeight.normal,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
