import 'package:costing_master/client/notifier/client_notifier.dart';
import 'package:costing_master/costings/repository/costings_repository.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/sync/sync_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ClientStats {
  final int count;

  /// When a costing of this client was last saved; null if never.
  final DateTime? lastUpdated;

  const ClientStats({required this.count, this.lastUpdated});
}

/// What the home screen shows above and inside the client list.
@immutable
class HomeSummary {
  static const recentLimit = 8;

  final int total;
  final int thisMonth;

  /// The latest saved costings across all clients, newest first.
  final List<Costing> recent;

  /// Keyed by client guid; clients without costings are absent.
  final Map<String, ClientStats> byClient;

  const HomeSummary({
    required this.total,
    required this.thisMonth,
    required this.recent,
    required this.byClient,
  });

  factory HomeSummary.of(List<Costing> costings, {DateTime? now}) {
    now ??= DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    DateTime? savedAt(Costing c) => c.updatedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(c.updatedAt!);

    final byClient = <String, ClientStats>{};
    var thisMonth = 0;
    for (final costing in costings) {
      final saved = savedAt(costing);
      if (saved != null && !saved.isBefore(monthStart)) thisMonth++;
      final stats = byClient[costing.clientGuid];
      final last = stats?.lastUpdated;
      byClient[costing.clientGuid] = ClientStats(
        count: (stats?.count ?? 0) + 1,
        lastUpdated: saved != null && (last == null || saved.isAfter(last))
            ? saved
            : last,
      );
    }

    final recent = [...costings]
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
    return HomeSummary(
      total: costings.length,
      thisMonth: thisMonth,
      recent: recent.take(recentLimit).toList(),
      byClient: byClient,
    );
  }
}

/// Rebuilt when clients change, after every sync and whenever a costing is
/// saved or deleted (the costings notifier invalidates it).
final homeSummaryProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(clientsProvider);
  ref.watch(syncProvider.select((s) => s.lastSyncAt));
  return HomeSummary.of(await ref.read(costingsRepositoryProvider).getAll());
});
