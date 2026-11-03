import 'dart:async';

import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/client/notifier/client_notifier.dart';
import 'package:costing_master/connectivity/notifier/connectivity_notifier.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/provider/firebase_provider.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/storage/image_storage.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:costing_master/sync/sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

final syncServiceProvider = Provider((ref) {
  final storage = ref.watch(imageStorageProvider);
  return SyncService(
    local: ref.watch(localDbProvider),
    firestore: ref.watch(firestoreProvider),
    uploadPhoto: (localRef, fileName) =>
        storage.upload(LocalImages.file(localRef), fileName: fileName),
  );
});

@immutable
class SyncState {
  final bool syncing;
  final bool failed;
  final DateTime? lastSyncAt;

  const SyncState({this.syncing = false, this.failed = false, this.lastSyncAt});
}

/// Keeps the backup in step with the phone: syncs when the user signs in,
/// when the internet comes back and shortly after every local change.
class SyncNotifier extends Notifier<SyncState> {
  static const _lastSyncKey = 'lastSyncAt';

  Future<void>? _running;
  bool _rerun = false;
  Timer? _debounce;

  LocalDb get _local => ref.read(localDbProvider);

  @override
  SyncState build() {
    ref.listen(connectivityProvider, (previous, next) {
      if (next.value == true && previous?.value != true) sync();
    });
    ref.listen(authProvider, (previous, next) {
      final uid = next.value?.uid;
      if (uid != null && uid != previous?.value?.uid) sync();
    });
    ref.onDispose(() => _debounce?.cancel());
    _loadLastSync();
    return const SyncState();
  }

  Future<void> _loadLastSync() async {
    final ms = await _local.meta.record(_lastSyncKey).get(_local.db) as int?;
    if (ms != null && state.lastSyncAt == null) {
      state = SyncState(
          syncing: state.syncing,
          failed: state.failed,
          lastSyncAt: DateTime.fromMillisecondsSinceEpoch(ms));
    }
  }

  /// Syncs a moment after a local write, so quick edits go up together.
  void syncSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), sync);
  }

  /// Does nothing for guests or while offline.
  Future<void> sync() {
    if (_running != null) {
      _rerun = true;
      return _running!;
    }
    return _running = _run().whenComplete(() {
      _running = null;
      if (_rerun) {
        _rerun = false;
        sync();
      }
    });
  }

  Future<void> _run() async {
    final uid = ref.read(authProvider).value?.uid;
    final online = ref.read(connectivityProvider).value ?? false;
    if (uid == null || !online) return;

    state = SyncState(syncing: true, lastSyncAt: state.lastSyncAt);
    try {
      final service = ref.read(syncServiceProvider);
      await service.push(uid);
      final changed = await service.pull(uid);
      final now = DateTime.now();
      await _local.meta
          .record(_lastSyncKey)
          .put(_local.db, now.millisecondsSinceEpoch);
      state = SyncState(lastSyncAt: now);
      if (changed) _reloadData();
    } catch (e) {
      debugPrint('Sync failed: $e');
      state = SyncState(failed: true, lastSyncAt: state.lastSyncAt);
    }
  }

  /// Signs out and removes the account's data from this phone; it stays in
  /// the backup and comes back on the next sign-in.
  Future<void> signOutAndClear() async {
    _debounce?.cancel();
    await _running;
    await ref.read(authProvider.notifier).logOut();
    await _local.clear();
    await LocalImages.clear();
    state = const SyncState();
    _reloadData();
  }

  void _reloadData() {
    ref.invalidate(clientsProvider);
    ref.invalidate(costingsProvider);
    ref.invalidate(settingsProvider);
  }
}

final syncProvider =
    NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
