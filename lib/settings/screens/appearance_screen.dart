import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/settings/widgets/settings_widgets.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _colorNames = {
  AppColor.system: ('ફોનના રંગ', 'Match my phone (wallpaper colours)'),
  AppColor.navy: ('નેવી બ્લૂ', 'Navy'),
  AppColor.teal: ('ટીલ', 'Teal'),
  AppColor.emerald: ('લીલો', 'Emerald'),
  AppColor.maroon: ('મરૂન', 'Maroon'),
  AppColor.graphite: ('ગ્રે', 'Graphite'),
};

/// Light/dark mode and the app's colour palette.
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    return SettingsPage(
      title: 'દેખાવ',
      body: (settings) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const SectionTitle('મોડ', 'Light or dark'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('ઓટો')),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('લાઇટ')),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('ડાર્ક')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => saveSettings(
                context, notifier, (all) => all.copyWith(themeMode: s.first)),
          ),
          const SectionTitle('રંગ', 'App colour'),
          Card(
            child: DynamicColorBuilder(
              builder: (wallpaper, _) => Column(
                children: [
                  for (final color in AppColor.values)
                    // Phones without wallpaper colours use the fallback.
                    if (color != AppColor.system || wallpaper != null)
                      _ColorTile(
                        color: color == AppColor.system
                            ? wallpaper!.primary
                            : color.seed,
                        names: _colorNames[color]!,
                        selected: settings.appColor == color ||
                            (wallpaper == null &&
                                settings.appColor == AppColor.system &&
                                color == AppColor.navy),
                        onTap: () => saveSettings(context, notifier,
                            (all) => all.copyWith(appColor: color)),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  final Color color;
  final (String, String) names;
  final bool selected;
  final VoidCallback onTap;

  const _ColorTile({
    required this.color,
    required this.names,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (gu, en) = names;
    return ListTile(
      onTap: onTap,
      leading: ColorSwatchButton(color: color, selected: false, onTap: onTap),
      title: Text(gu, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(en),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: context.colors.primary)
          : null,
    );
  }
}
