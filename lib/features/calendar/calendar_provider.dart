import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/vault/vault_provider.dart';

/// Set of ISO date strings (YYYY-MM-DD) for every date that has a journal
/// entry. Refreshes whenever the active vault changes.
final entryDatesProvider = FutureProvider<Set<String>>((ref) async {
  final vault = ref.watch(vaultProvider).valueOrNull;
  if (vault == null) return const {};

  final service = ref.read(vaultServiceProvider);
  final dates = await service.listEntryDates(vault);

  return {
    for (final d in dates)
      '${d.year.toString().padLeft(4, '0')}'
          '-${d.month.toString().padLeft(2, '0')}'
          '-${d.day.toString().padLeft(2, '0')}',
  };
});
