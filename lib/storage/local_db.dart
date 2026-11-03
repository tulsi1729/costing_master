import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// The on-device database every screen reads and writes. Firestore is only a
/// backup that [SyncNotifier] copies to and from once the user signs in.
class LocalDb {
  LocalDb(this.db);

  final Database db;

  /// Set on records changed on this phone and not yet uploaded. It holds the
  /// write time, so an upload only clears it if nothing changed meanwhile.
  static const dirtyField = '_dirty';

  /// Key of the single record in [settings].
  static const settingsKey = 'current';

  final clients = stringMapStoreFactory.store('clients');
  final costings = stringMapStoreFactory.store('costings');
  final settings = stringMapStoreFactory.store('settings');

  /// Device-only values (sync time, backup nudge state); never uploaded.
  final meta = StoreRef<String, Object?>('meta');

  /// Deleted records are kept with this flag (and a fresh `updatedAt`), so
  /// the delete is backed up and reaches the user's other phones.
  static const deletedField = 'deleted';

  static final dirtyFilter = Filter.notNull(dirtyField);
  static final dirtyFinder = Finder(filter: dirtyFilter);
  static final notDeleted = Filter.notEquals(deletedField, true);

  /// [data] marked as changed on this phone.
  static Map<String, Object?> dirty(Map<String, Object?> data) =>
      {...data, dirtyField: DateTime.now().microsecondsSinceEpoch};

  /// [data] marked as deleted ([deleted] true) or brought back (false) at
  /// [at] (epoch milliseconds, default now).
  static Map<String, Object?> withDeleted(
          Map<String, Object?> data, bool deleted,
          {int? at}) =>
      dirty({
        ...data,
        deletedField: deleted,
        'updatedAt': at ?? DateTime.now().millisecondsSinceEpoch,
      });

  static Future<LocalDb> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return LocalDb(
        await databaseFactoryIo.openDatabase('${dir.path}/costing_master.db'));
  }

  Future<int> pendingCount() async =>
      await clients.count(db, filter: dirtyFilter) +
      await costings.count(db, filter: dirtyFilter) +
      await settings.count(db, filter: dirtyFilter);

  /// Removes everything, e.g. after the user signs out.
  Future<void> clear() => db.transaction((txn) async {
        for (final store in [clients, costings, settings]) {
          await store.delete(txn);
        }
        await meta.delete(txn);
      });
}

final localDbProvider = Provider<LocalDb>(
    (ref) => throw UnimplementedError('Overridden in main() once opened'));
