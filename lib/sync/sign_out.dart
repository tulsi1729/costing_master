import 'package:costing_master/storage/local_db.dart';
import 'package:costing_master/sync/sync_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Confirms, then signs out and clears this phone (the data stays in the
/// backup). If some changes could not be uploaded, says they will be lost.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final sync = ref.read(syncProvider.notifier);
  await sync.sync();
  final pending = await ref.read(localDbProvider).pendingCount();
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('લૉગ આઉટ કરવું છે?'),
      content: Text(pending > 0
          ? '$pending ફેરફાર હજુ બેકઅપ થયા નથી અને ગુમ થઈ જશે. પહેલાં ઇન્ટરનેટ ચાલુ કરો.\n'
              '$pending changes are not backed up yet and will be lost.'
          : 'આ ફોનમાંથી ડેટા નીકળી જશે, ફરી સાઇન ઇન કરતાં બેકઅપમાંથી પાછો આવશે.\n'
              'Your data leaves this phone and returns when you sign in again.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('રહેવા દો'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context, true),
          child: Text(pending > 0 ? 'તોય લૉગ આઉટ' : 'લૉગ આઉટ'),
        ),
      ],
    ),
  );
  if (confirmed == true) await sync.signOutAndClear();
}
