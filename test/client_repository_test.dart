import 'package:costing_master/client/repository/client_repository.dart';
import 'package:costing_master/costings/repository/costings_repository.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late LocalDb local;
  late ClientRepository clients;
  late CostingsRepository costings;

  Map<String, Object?> costing(String guid) => {
        'guid': guid,
        'createdBy': '',
        'clientGuid': 'c1',
        'sariName': guid,
        'imageUrl': '',
      };

  setUp(() async {
    local = LocalDb(await newDatabaseFactoryMemory().openDatabase('test.db'));
    clients = ClientRepository(local);
    costings = CostingsRepository(local);
    await clients.saveClient(Client(guid: 'c1', name: 'Asha', createdBy: ''));
    for (final guid in ['k1', 'k2']) {
      await local.costings.record(guid).put(local.db, costing(guid));
    }
  });

  Future<List<String>> visibleCostings() async =>
      [for (final c in await costings.getClientCostings('c1')) c.guid]..sort();

  test('deleting a client hides it with its costings until restored', () async {
    await clients.delete('c1');
    expect(await clients.getClients(), isEmpty);
    expect(await visibleCostings(), isEmpty);
    expect(await local.pendingCount(), 3, reason: 'deletes are backed up');

    await clients.restore('c1');
    expect((await clients.getClients()).single.name, 'Asha');
    expect(await visibleCostings(), ['k1', 'k2']);
  });

  test('undoing a client delete keeps costings deleted before it', () async {
    await costings.delete('k1');
    // A later delete gets a later timestamp than the costing's own delete.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await clients.delete('c1');
    await clients.restore('c1');

    expect(await visibleCostings(), ['k2']);
  });
}
