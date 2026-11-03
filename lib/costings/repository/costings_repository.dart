import 'dart:isolate';

import 'package:costing_master/model/costing.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/utils/value_utils.dart';

final costingsRepositoryProvider = Provider((ref) {
  return CostingsRepository(ref.watch(localDbProvider));
});

/// Above this many documents, parsing moves to a background isolate so
/// scrolling and transitions stay smooth.
const _isolateParseThreshold = 50;

class CostingsRepository {
  final LocalDb _local;

  CostingsRepository(this._local);

  Future<List<Costing>> getClientCostings(String clientGuid) async {
    final records = await _local.costings.find(_local.db,
        finder: Finder(
            filter: Filter.and([
          Filter.equals('clientGuid', clientGuid),
          LocalDb.notDeleted,
        ])));
    return _parseAll([for (final r in records) cloneMap(r.value)]);
  }

  static Future<List<Costing>> _parseAll(
      List<Map<String, dynamic>> maps) async {
    if (maps.length < _isolateParseThreshold) return _parse(maps);
    return Isolate.run(() => _parse(maps));
  }

  /// Every costing of every client, e.g. for the home screen summary.
  Future<List<Costing>> getAll() async {
    final records = await _local.costings
        .find(_local.db, finder: Finder(filter: LocalDb.notDeleted));
    return _parseAll([for (final r in records) cloneMap(r.value)]);
  }

  Future<int> count() =>
      _local.costings.count(_local.db, filter: LocalDb.notDeleted);

  /// Creates or overwrites the costing record (its key is the costing guid).
  Future<void> saveCosting(Costing costing) => _local.costings
      .record(costing.guid)
      .put(_local.db, LocalDb.dirty(costing.toMap()));

  /// Deletes the costing; [restore] undoes it.
  Future<void> delete(String guid) => _setDeleted(guid, true);

  Future<void> restore(String guid) => _setDeleted(guid, false);

  Future<void> _setDeleted(String guid, bool deleted) =>
      _local.db.transaction((txn) async {
        final record = _local.costings.record(guid);
        final costing = await record.get(txn);
        if (costing != null) {
          await record.put(txn, LocalDb.withDeleted(costing, deleted));
        }
      });

  static List<Costing> _parse(List<Map<String, dynamic>> maps) =>
      [for (final map in maps) Costing.fromMap(map)];
}
