import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/settings/screens/appearance_screen.dart';
import 'package:costing_master/settings/screens/business_profile_screen.dart';
import 'package:costing_master/settings/screens/quote_design_screen.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/settings/widgets/settings_widgets.dart';
import 'package:costing_master/sync/backup_card.dart';
import 'package:costing_master/sync/sign_out.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings home: backup status on top, then one entry per area. Each area
/// is its own screen so none of them tries to do everything.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final businessName = settings?.profile.businessName ?? '';
    final signedIn = ref.watch(authProvider.select((u) => u.value != null));

    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: const Text('સેટિંગ્સ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const SectionTitle('બેકઅપ', 'Backup & sync'),
          const BackupCard(),
          const SectionTitle('બિઝનેસ', 'Your business & quotes'),
          Card(
            child: Column(
              children: [
                _Entry(
                  icon: Icons.storefront_outlined,
                  title: 'બિઝનેસ પ્રોફાઇલ',
                  subtitle: businessName.isEmpty
                      ? 'નામ, લોગો, ફોન ઉમેરો · Add name, logo, phone'
                      : businessName,
                  onTap: () => open(const BusinessProfileScreen()),
                ),
                const Divider(indent: 72),
                _Entry(
                  icon: Icons.receipt_long_outlined,
                  title: 'કોસ્ટિંગની ડિઝાઇન',
                  subtitle: 'Quote template, colour, what to show',
                  onTap: () => open(const QuoteDesignScreen()),
                ),
              ],
            ),
          ),
          const SectionTitle('એપ', 'App'),
          Card(
            child: _Entry(
              icon: Icons.palette_outlined,
              title: 'દેખાવ',
              subtitle: _appearanceSummary(settings),
              onTap: () => open(const AppearanceScreen()),
            ),
          ),
          if (signedIn) ...[
            const SectionTitle('એકાઉન્ટ', 'Account'),
            Card(
              child: _Entry(
                icon: Icons.logout_rounded,
                title: 'લૉગ આઉટ',
                subtitle: 'Log out of backup on this phone',
                onTap: () => confirmSignOut(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _appearanceSummary(AppSettings? settings) {
    final mode = switch (settings?.themeMode ?? ThemeMode.system) {
      ThemeMode.system => 'Auto',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
    final color = switch (settings?.appColor ?? AppColor.system) {
      AppColor.system => 'phone colours',
      final c => c.name,
    };
    return 'Theme: $mode · $color';
  }
}

class _Entry extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: context.colors.primaryContainer,
        foregroundColor: context.colors.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
