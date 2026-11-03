import 'package:costing_master/model/client.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

final clientRepositoryProvider = Provider((ref) {
  return ClientRepository(ref.watch(localDbProvider));
});

class ClientRepository {
  final LocalDb _local;

  ClientRepository(this._local);

  /// Creates or overwrites the client record (its key is the client guid).
  Future<void> saveClient(Client client) => _local.clients
      .record(client.guid)
      .put(_local.db, LocalDb.dirty(client.toMap()));

  Future<List<Client>> getClients() async {
    final records = await _local.clients
        .find(_local.db, finder: Finder(filter: LocalDb.notDeleted));
    return [for (final r in records) Client.fromMap(r.value)];
  }

  /// Deletes the client together with its costings; [restore] undoes it.
  Future<void> delete(String clientGuid) => _setDeleted(clientGuid, true);

  Future<void> restore(String clientGuid) => _setDeleted(clientGuid, false);

  Future<void> _setDeleted(String clientGuid, bool deleted) =>
      _local.db.transaction((txn) async {
        final client = await _local.clients.record(clientGuid).get(txn);
        if (client == null) return;
        final now = DateTime.now().millisecondsSinceEpoch;
        final costings = await _local.costings.find(txn,
            finder: Finder(
                filter: Filter.and([
              Filter.equals('clientGuid', clientGuid),
              if (deleted)
                LocalDb.notDeleted
              else ...[
                // Only what the client's delete removed, which shares its
                // time; costings deleted on their own earlier stay deleted.
                Filter.equals(LocalDb.deletedField, true),
                Filter.equals('updatedAt', client['updatedAt']),
              ],
            ])));
        await _local.clients
            .record(clientGuid)
            .put(txn, LocalDb.withDeleted(client, deleted, at: now));
        for (final costing in costings) {
          await costing.ref
              .put(txn, LocalDb.withDeleted(costing.value, deleted, at: now));
        }
      });
}
