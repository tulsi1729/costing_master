import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/repository/auth_repository.dart';
import 'package:costing_master/domain/time_ago.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:costing_master/sync/backup_sheet.dart';
import 'package:costing_master/sync/sync_notifier.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

/// How many costings are on the phone and how many changes await upload.
final _summaryProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(syncProvider); // Recount after every sync.
  final local = ref.watch(localDbProvider);
  return (
    costings: await local.costings.count(local.db),
    pending: await local.pendingCount(),
  );
});

/// Backup status at the top of Settings. For guests it states what they
/// would lose without a backup; for signed-in users, when it last synced.
class BackupCard extends ConsumerWidget {
  const BackupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider.select((u) => u.value != null));
    final summary = ref.watch(_summaryProvider).value;
    return signedIn
        ? _SyncedCard(pending: summary?.pending ?? 0)
        : _GuestCard(costings: summary?.costings ?? 0);
  }
}

class _GuestCard extends StatelessWidget {
  final int costings;
  const _GuestCard({required this.costings});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.smartphone_rounded,
                    color: context.colors.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    costings > 0
                        ? '$costings કોસ્ટિંગ ફક્ત આ ફોનમાં છે'
                        : 'તમારો ડેટા ફક્ત આ ફોનમાં છે',
                    style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ફોન ખોવાય કે બદલાય તો તે પાછો નહીં મળે. Google થી મફત બેકઅપ કરો.',
              style: TextStyle(color: context.colors.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => showBackupSheet(context, costingCount: costings),
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('બેકઅપ ચાલુ કરો · Back up'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncedCard extends ConsumerWidget {
  final int pending;
  const _SyncedCard({required this.pending});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);
    final email = ref.read(authRepositoryProvider).currentUser?.email ?? '';
    final last = sync.lastSyncAt;
    final status = sync.syncing
        ? 'સિંક થાય છે… · Syncing'
        : sync.failed
            ? 'છેલ્લું સિંક ન થયું · Last sync failed'
            : pending > 0
                ? '$pending ફેરફાર ઇન્ટરનેટ મળતાં અપલોડ થશે'
                : last != null
                    ? 'છેલ્લે સિંક: ${timeAgo(last)}'
                    : '';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: sync.syncing
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5))
            : Icon(
                sync.failed
                    ? Icons.cloud_off_rounded
                    : Icons.cloud_done_rounded,
                color: sync.failed
                    ? context.colors.error
                    : context.colors.primary),
        title: const Text('બેકઅપ ચાલુ છે · Backed up',
            style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text([status, email].where((s) => s.isNotEmpty).join('\n')),
        trailing: IconButton(
          tooltip: 'હમણાં સિંક કરો · Sync now',
          icon: const Icon(Icons.sync_rounded),
          onPressed: sync.syncing ? null : ref.read(syncProvider.notifier).sync,
        ),
      ),
    );
  }
}
