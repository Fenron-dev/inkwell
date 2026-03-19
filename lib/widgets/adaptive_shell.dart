import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:inkwell/l10n/app_localizations.dart';

import '../features/quick_capture/quick_capture_dialog.dart';

/// Responsive shell that shows a NavigationBar on mobile
/// and a NavigationRail on desktop/tablet.
class AdaptiveShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdaptiveShell({super.key, required this.navigationShell});

  static const _breakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _breakpoint;

    final destinations = [
      _Destination(icon: Icons.edit_note, label: l10n?.navDaily ?? 'Heute'),
      _Destination(icon: Icons.calendar_month, label: l10n?.navCalendar ?? 'Kalender'),
      _Destination(icon: Icons.search, label: l10n?.navSearch ?? 'Suche'),
      _Destination(icon: Icons.settings, label: l10n?.navSettings ?? 'Einstellungen'),
    ];

    final fab = FloatingActionButton(
      heroTag: 'quickCapture',
      tooltip: l10n?.quickCaptureTooltip ?? 'Quick Capture',
      onPressed: () => QuickCaptureDialog.show(context),
      child: const Icon(Icons.add),
    );

    // Ctrl+Shift+Space opens quick capture while the app is focused
    final shell = CallbackShortcuts(
      bindings: {
        const SingleActivator(
          LogicalKeyboardKey.space,
          control: true,
          shift: true,
        ): () => QuickCaptureDialog.show(context),
      },
      child: Focus(autofocus: false, child: navigationShell),
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) =>
                  navigationShell.goBranch(index),
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: shell),
          ],
        ),
        floatingActionButton: fab,
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  label: d.label,
                ))
            .toList(),
      ),
      floatingActionButton: fab,
    );
  }
}

class _Destination {
  final IconData icon;
  final String label;
  const _Destination({required this.icon, required this.label});
}
