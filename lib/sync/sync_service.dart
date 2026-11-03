import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:costing_master/constant/firebase_constants.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/storage/image_storage.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/utils/value_utils.dart';

/// Uploads the `local:` photo [localRef] and returns its download URL.
typedef PhotoUploader = Future<String> Function(
    String localRef, String fileName);

typedef _Store = StoreRef<String, Map<String, Object?>>;

/// Copies data between the phone and the signed-in user's Firestore backup.
///
/// Collections, doc ids and fields are the same as v1 of the app, so the
/// backup stays readable by older versions.
class SyncService {
  SyncService({
    required LocalDb local,
    required FirebaseFirestore firestore,
    required PhotoUploader uploadPhoto,
  })  : _local = local,
        _firestore = firestore,
        _uploadPhoto = uploadPhoto;

  final LocalDb _local;
  final FirebaseFirestore _firestore;
  final PhotoUploader _uploadPhoto;

  List<(_Store, String)> get _collections => [
        (_local.clients, FirebaseConstants.clientsCollection),
        (_local.costings, FirebaseConstants.costingsColletion),
      ];

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  /// Uploads every record changed on this phone, owned by [uid].
  Future<void> push(String uid) async {
    for (final (store, collection) in _collections) {
      final records = await store.find(_local.db, finder: LocalDb.dirtyFinder);
      for (final record in records) {
        final data = cloneMap(record.value)
          ..remove(LocalDb.dirtyField)
          ..['createdBy'] = uid;
        final photo = data['imageUrl'];
        if (photo is String && LocalImages.isLocal(photo)) {
          data['imageUrl'] =
              await _uploadPhoto(photo, _photoName(uid, record.key));
        }
        await _firestore.collection(collection).doc(record.key).set(data);
        await _markClean(store, record, data, photo);
      }
    }
    await _pushSettings(uid);
  }

  Future<void> _pushSettings(String uid) async {
    final record = await _local.settings
        .record(LocalDb.settingsKey)
        .getSnapshot(_local.db);
    if (record == null || record.value[LocalDb.dirtyField] == null) return;
    var settings = AppSettings.fromMap(cloneMap(record.value));
    final logo = settings.profile.logoUrl;
    if (LocalImages.isLocal(logo)) {
      final url = await _uploadPhoto(logo, _photoName(uid, 'logo'));
      settings =
          settings.copyWith(profile: settings.profile.copyWith(logoUrl: url));
    }
    final data = settings.toMap();
    await _users.doc(uid).set(data, SetOptions(merge: true));
    await _markClean(_local.settings, record, data, logo);
  }

  /// Stores the uploaded [data] locally, unless the record was edited during
  /// the upload; then it stays dirty and goes up on the next sync.
  Future<void> _markClean(
      _Store store,
      RecordSnapshot<String, Map<String, Object?>> uploaded,
      Map<String, Object?> data,
      Object? photo) async {
    final clean = await _local.db.transaction((txn) async {
      final current = await store.record(uploaded.key).get(txn);
      final sameWrite =
          current?[LocalDb.dirtyField] == uploaded.value[LocalDb.dirtyField];
      if (sameWrite) await store.record(uploaded.key).put(txn, data);
      return sameWrite;
    });
    // The photo now lives in the backup; the phone copy is no longer used.
    if (clean && photo is String && LocalImages.isLocal(photo)) {
      try {
        await LocalImages.file(photo).delete();
      } on FileSystemException catch (_) {}
    }
  }

  /// Merges the backup of [uid] into the phone and returns whether anything
  /// changed. Records edited on the phone win; otherwise the newer
  /// `updatedAt` wins. Deletes travel the same way, as records flagged
  /// [LocalDb.deletedField].
  Future<bool> pull(String uid) async {
    var changed = false;
    for (final (store, collection) in _collections) {
      final snapshot = await _firestore
          .collection(collection)
          .where(FirebaseConstants.createdBy, isEqualTo: uid)
          .get();
      await _local.db.transaction((txn) async {
        for (final doc in snapshot.docs) {
          final record = store.record(doc.id);
          final local = await record.get(txn);
          final remote = doc.data();
          if (local == null ||
              (local[LocalDb.dirtyField] == null &&
                  _updatedAt(remote) > _updatedAt(local))) {
            await record.put(txn, remote);
            changed = true;
          }
        }
      });
    }

    final remoteSettings = (await _users.doc(uid).get()).data();
    if (remoteSettings != null) {
      final settings = AppSettings.fromMap(remoteSettings).toMap();
      final record = _local.settings.record(LocalDb.settingsKey);
      changed |= await _local.db.transaction((txn) async {
        final local = await record.get(txn);
        if (local?[LocalDb.dirtyField] != null) return false;
        if (local != null && jsonEncode(local) == jsonEncode(settings)) {
          return false;
        }
        await record.put(txn, settings);
        return true;
      });
    }
    return changed;
  }

  static int _updatedAt(Map<String, Object?> map) =>
      (map['updatedAt'] as num?)?.toInt() ?? 0;

  static String _photoName(String uid, String key) =>
      '${uid}_${key}_${DateTime.now().millisecondsSinceEpoch}';
}
