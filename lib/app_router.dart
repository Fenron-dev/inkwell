import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/security/lock_provider.dart';
import 'core/vault/vault_provider.dart';
import 'features/daily_notes/daily_notes_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/lock/lock_screen.dart';
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
    refreshListenable: _AppStateListenable(ref),
    redirect: (context, state) {
      final vaultState = ref.read(vaultProvider);
      final lockState = ref.read(lockProvider);

      // While vault is loading, don't redirect
      if (vaultState.isLoading) return null;

      final hasVault = vaultState.valueOrNull != null;
      final isOnSetup = state.matchedLocation == '/setup';
      final isOnLock = state.matchedLocation == '/lock';

      if (!hasVault && !isOnSetup) return '/setup';
      if (hasVault && isOnSetup) return '/daily';

      // App lock: redirect to /lock when locked, away from /lock when unlocked
      if (lockState.isLocked && !isOnLock && !isOnSetup) return '/lock';
      if (!lockState.isLocked && isOnLock) return '/daily';

      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
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

/// Bridges Riverpod state changes (vault + lock) to GoRouter's Listenable refresh.
class _AppStateListenable extends ChangeNotifier {
  _AppStateListenable(Ref ref) {
    ref.listen(vaultProvider, (_, _) => notifyListeners());
    ref.listen(lockProvider, (_, _) => notifyListeners());
  }
}
