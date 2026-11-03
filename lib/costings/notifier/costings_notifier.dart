import 'package:costing_master/client/notifier/home_summary.dart';
import 'package:costing_master/costings/repository/costings_repository.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/sync/sync_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Costings of one client (the family argument is the client guid).
class CostingsNotifier extends AsyncNotifier<List<Costing>> {
  CostingsNotifier(this.clientGuid);

  final String clientGuid;

  @override
  Future<List<Costing>> build() =>
      ref.read(costingsRepositoryProvider).getClientCostings(clientGuid);

  /// Saves [costing] and updates the list in place, without a refetch.
  Future<void> save(Costing costing) async {
    await ref.read(costingsRepositoryProvider).saveCosting(costing);
    ref.read(syncProvider.notifier).syncSoon();
    ref.invalidate(homeSummaryProvider);
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      costing,
      for (final c in current)
        if (c.guid != costing.guid) c,
    ]);
  }

  /// Deletes [costing]; [restore] brings it back.
  Future<void> delete(Costing costing) async {
    await ref.read(costingsRepositoryProvider).delete(costing.guid);
    ref.read(syncProvider.notifier).syncSoon();
    ref.invalidate(homeSummaryProvider);
    state = AsyncData([
      for (final c in state.value ?? const <Costing>[])
        if (c.guid != costing.guid) c,
    ]);
  }

  Future<void> restore(Costing costing) async {
    await ref.read(costingsRepositoryProvider).restore(costing.guid);
    ref.read(syncProvider.notifier).syncSoon();
    ref.invalidate(homeSummaryProvider);
    ref.invalidateSelf();
  }
}

final costingsProvider =
    AsyncNotifierProvider.family<CostingsNotifier, List<Costing>, String>(
        CostingsNotifier.new);
