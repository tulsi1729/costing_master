import 'package:costing_master/client/notifier/client_notifier.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks, then deletes [client] with its costings, offering an undo.
/// Returns whether the client was deleted.
Future<bool> deleteClientWithUndo(
    BuildContext context, WidgetRef ref, Client client) async {
  final count = (await ref.read(costingsProvider(client.guid).future)).length;
  if (!context.mounted) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_outline_rounded),
      title: Text('${client.name} ડિલીટ કરવા છે?'),
      content: Text(count == 0
          ? 'Delete this trader?'
          : 'તેમની $count કોસ્ટિંગ પણ ડિલીટ થશે.\n'
              'Their $count costings will be deleted too.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('રહેવા દો'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('ડિલીટ કરો'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final notifier = ref.read(clientsProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await notifier.delete(client);
  } catch (_) {
    if (context.mounted) {
      showAppSnack(context, 'ડિલીટ ન થયું · Could not delete',
          type: SnackType.error);
    }
    return false;
  }
  if (context.mounted) {
    showAppSnack(
      context,
      '${client.name} ડિલીટ થયા',
      action: SnackBarAction(
        label: 'પાછું લાવો',
        onPressed: () => notifier.restore(client).catchError((Object _) {
          messenger.showSnackBar(
              const SnackBar(content: Text('પાછું ન આવ્યું · Undo failed')));
        }),
      ),
    );
  }
  return true;
}
