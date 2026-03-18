import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkwell/l10n/app_localizations.dart';

/// Responsive shell that shows a NavigationBar on mobile
/// and a NavigationRail on desktop/tablet.
class AdaptiveShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdaptiveShell({super.key, required this.navigationShell});

  static const _breakpoint = 600.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _breakpoint;

    final destinations = [
      _Destination(icon: Icons.edit_note, label: l10n.navDaily),
      _Destination(icon: Icons.calendar_month, label: l10n.navCalendar),
      _Destination(icon: Icons.search, label: l10n.navSearch),
      _Destination(icon: Icons.settings, label: l10n.navSettings),
    ];

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
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
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
    );
  }
}

class _Destination {
  final IconData icon;
  final String label;
  const _Destination({required this.icon, required this.label});
}
