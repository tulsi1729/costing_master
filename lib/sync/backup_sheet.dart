import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/sign_in_button.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Offers Google backup to a guest. Resolves to true once they signed in.
///
/// [costingCount] makes the ask concrete ("your 12 costings are only on this
/// phone"); [restore] words it for someone who backed up before.
Future<bool> showBackupSheet(BuildContext context,
    {int costingCount = 0, bool restore = false}) async {
  final signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _BackupSheet(costingCount: costingCount, restore: restore),
  );
  return signedIn ?? false;
}

class _BackupSheet extends ConsumerWidget {
  final int costingCount;
  final bool restore;

  const _BackupSheet({required this.costingCount, required this.restore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      switch (next) {
        case AsyncData(value: _?):
          showAppSnack(context, 'બેકઅપ ચાલુ થયું · Backup is on',
              type: SnackType.success);
          Navigator.pop(context, true);
        case AsyncError():
          showAppSnack(
              context, 'સાઇન ઇન ન થયું, ફરી પ્રયત્ન કરો · Sign-in failed',
              type: SnackType.error);
        default:
      }
    });

    final message = restore
        ? 'જે Google એકાઉન્ટથી બેકઅપ કર્યું હતું તેનાથી સાઇન ઇન કરો, બધું પાછું આવી જશે.'
        : costingCount > 0
            ? 'તમારી $costingCount કોસ્ટિંગ ફક્ત આ ફોનમાં છે. ફોન ખોવાય કે બદલાય તો તે પાછી નહીં મળે.'
            : 'ફોન ખોવાય કે બદલાય તો પણ તમારી કોસ્ટિંગ સલામત રહેશે.';
    const benefits = [
      (Icons.phonelink_setup_rounded, 'નવા ફોનમાં બધું પાછું મળશે'),
      (Icons.devices_rounded, 'બે ફોનમાં સાથે વાપરો'),
      (Icons.volunteer_activism_outlined, 'સંપૂર્ણ મફત · Free'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: context.brand.heroGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                  restore
                      ? Icons.cloud_download_rounded
                      : Icons.cloud_upload_rounded,
                  color: context.brand.heroAccent,
                  size: 40),
              const SizedBox(height: 12),
              Text(
                restore
                    ? 'બેકઅપમાંથી પાછું લાવો'
                    : 'તમારી કોસ્ટિંગ સુરક્ષિત રાખો',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
              Text(
                restore ? 'Restore from backup' : 'Protect your costings',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Text(message,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              if (!restore) ...[
                const SizedBox(height: 18),
                for (final (icon, text) in benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(icon, color: context.brand.heroAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(text,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 18),
              const SignInButton(),
              const SizedBox(height: 12),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: Colors.white70, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google ફક્ત તમારા બેકઅપ માટે વપરાય છે. બેકઅપ ચાલુ ન કરો ત્યાં સુધી તમારા ભાવ આ ફોનમાં જ રહે છે.',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('પછી કરીશ · Later'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
