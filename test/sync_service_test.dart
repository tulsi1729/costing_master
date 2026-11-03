import 'package:costing_master/storage/local_db.dart';
import 'package:costing_master/sync/sync_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart' hide Finder;
import 'package:sembast/sembast_memory.dart';

void main() {
  late LocalDb local;
  late FakeFirebaseFirestore firestore;
  late SyncService sync;

  setUp(() async {
    local = LocalDb(await newDatabaseFactoryMemory().openDatabase('test.db'));
    firestore = FakeFirebaseFirestore();
    sync = SyncService(
      local: local,
      firestore: firestore,
      uploadPhoto: (_, __) async => fail('no photos in these tests'),
    );
  });

  Map<String, Object?> costing(String guid, {int updatedAt = 1}) => {
        'guid': guid,
        'createdBy': '',
        'clientGuid': 'c1',
        'sariName': 'Rani $updatedAt',
        'imageUrl': 'https://example.com/a.jpg',
        'updatedAt': updatedAt,
      };

  test('push uploads guest records under the uid and marks them clean',
      () async {
    await local.clients.record('c1').put(local.db,
        LocalDb.dirty({'guid': 'c1', 'name': 'Asha', 'createdBy': ''}));
    await local.costings
        .record('k1')
        .put(local.db, LocalDb.dirty(costing('k1')));

    await sync.push('u1');

    final remote = await firestore.collection('costings').doc('k1').get();
    expect(remote.data()!['createdBy'], 'u1');
    expect(remote.data()!.containsKey(LocalDb.dirtyField), isFalse);
    expect(
        (await firestore.collection('clients').doc('c1').get()).exists, isTrue);
    expect(await local.pendingCount(), 0);
  });

  test('pull restores a backup onto an empty phone', () async {
    await firestore
        .collection('costings')
        .doc('k1')
        .set({...costing('k1'), 'createdBy': 'u1'});
    await firestore
        .collection('costings')
        .doc('other')
        .set({...costing('other'), 'createdBy': 'someone-else'});
    await firestore.collection('users').doc('u1').set({
      'name': 'Asha',
      'uid': 'u1',
      'profile': {'businessName': 'Shree Crafts'},
    });

    expect(await sync.pull('u1'), isTrue);

    expect(await local.costings.count(local.db), 1);
    final settings =
        await local.settings.record(LocalDb.settingsKey).get(local.db);
    expect((settings!['profile'] as Map)['businessName'], 'Shree Crafts');
    expect(await sync.pull('u1'), isFalse, reason: 'nothing new second time');
  });

  test('pull keeps unsynced phone edits and takes newer clean ones', () async {
    await firestore
        .collection('costings')
        .doc('edited')
        .set({...costing('edited', updatedAt: 9), 'createdBy': 'u1'});
    await firestore
        .collection('costings')
        .doc('stale')
        .set({...costing('stale', updatedAt: 9), 'createdBy': 'u1'});
    await local.costings
        .record('edited')
        .put(local.db, LocalDb.dirty(costing('edited', updatedAt: 5)));
    await local.costings
        .record('stale')
        .put(local.db, costing('stale', updatedAt: 5));

    await sync.pull('u1');

    final edited = await local.costings.record('edited').get(local.db);
    final stale = await local.costings.record('stale').get(local.db);
    expect(edited!['updatedAt'], 5);
    expect(stale!['updatedAt'], 9);
  });

  test('a deleted costing is backed up as deleted and stays deleted', () async {
    await local.costings
        .record('k1')
        .put(local.db, LocalDb.withDeleted(costing('k1'), true));

    await sync.push('u1');
    final remote = await firestore.collection('costings').doc('k1').get();
    expect(remote.data()![LocalDb.deletedField], isTrue);

    expect(await sync.pull('u1'), isFalse);
    expect(await local.costings.count(local.db, filter: LocalDb.notDeleted), 0);
  });

  test('notDeleted keeps records that never had the flag', () async {
    await local.costings.record('old').put(local.db, costing('old'));
    await local.costings
        .record('gone')
        .put(local.db, {...costing('gone'), LocalDb.deletedField: true});
    await local.costings
        .record('back')
        .put(local.db, {...costing('back'), LocalDb.deletedField: false});

    final keys = await local.costings
        .findKeys(local.db, finder: Finder(filter: LocalDb.notDeleted));
    expect(keys..sort(), ['back', 'old']);
  });

  test('a client edited on another phone replaces the clean local copy',
      () async {
    await local.clients
        .record('c1')
        .put(local.db, {'guid': 'c1', 'name': 'Asha', 'createdBy': 'u1'});
    await firestore.collection('clients').doc('c1').set({
      'guid': 'c1',
      'name': 'Asha Textiles',
      'createdBy': 'u1',
      'updatedAt': 5,
    });

    expect(await sync.pull('u1'), isTrue);
    final client = await local.clients.record('c1').get(local.db);
    expect(client!['name'], 'Asha Textiles');
  });
}
