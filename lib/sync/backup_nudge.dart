import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/costings/repository/costings_repository.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:costing_master/sync/backup_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

/// Saved-costing counts at which a guest is reminded to back up: right
/// after a save, when they have just got value from the app and have
/// something worth protecting.
const _milestones = {3, 10, 25};

/// After this many "Later"s we stop asking; the card in Settings remains.
const _maxDismissals = 3;
const _cooldown = Duration(days: 7);

const _shownAtKey = 'backupNudgeShownAt';
const _dismissalsKey = 'backupNudgeDismissals';

Future<void> maybeShowBackupNudge(BuildContext context, WidgetRef ref) async {
  if (ref.read(authProvider).value != null) return;
  final local = ref.read(localDbProvider);
  final count = await ref.read(costingsRepositoryProvider).count();
  if (!_milestones.contains(count)) return;

  final dismissals =
      await local.meta.record(_dismissalsKey).get(local.db) as int? ?? 0;
  final shownAt =
      await local.meta.record(_shownAtKey).get(local.db) as int? ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  if (dismissals >= _maxDismissals ||
      now - shownAt < _cooldown.inMilliseconds) {
    return;
  }

  await local.meta.record(_shownAtKey).put(local.db, now);
  if (!context.mounted) return;
  final backedUp = await showBackupSheet(context, costingCount: count);
  if (!backedUp) {
    await local.meta.record(_dismissalsKey).put(local.db, dismissals + 1);
  }
}
