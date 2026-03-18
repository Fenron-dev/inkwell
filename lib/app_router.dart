import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/vault/vault_provider.dart';
import 'features/daily_notes/daily_notes_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/setup_screen.dart';
import 'widgets/adaptive_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// A Riverpod provider that holds the GoRouter instance.
/// Using a provider ensures the router is created once and stays stable,
/// while still having access to the vault state for redirect logic.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/daily',
    refreshListenable: _VaultListenable(ref),
    redirect: (context, state) {
      final vaultState = ref.read(vaultProvider);

      // While vault is loading, don't redirect
      if (vaultState.isLoading) return null;

      final hasVault = vaultState.valueOrNull != null;
      final isOnSetup = state.matchedLocation == '/setup';

      if (!hasVault && !isOnSetup) return '/setup';
      if (hasVault && isOnSetup) return '/daily';
      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdaptiveShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/daily',
              builder: (context, state) {
                final dateStr = state.uri.queryParameters['date'];
                final date =
                    dateStr != null ? DateTime.tryParse(dateStr) : null;
                return DailyNotesScreen(initialDate: date);
              },
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod vault state changes to GoRouter's Listenable refresh.
class _VaultListenable extends ChangeNotifier {
  _VaultListenable(Ref ref) {
    ref.listen(vaultProvider, (_, _) => notifyListeners());
  }
}
