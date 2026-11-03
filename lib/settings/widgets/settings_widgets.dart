import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:costing_master/widgets/empty_state.dart';

export 'package:costing_master/widgets/section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A settings page that only builds [body] once the saved settings are
/// known, so a form never starts empty and overwrites them.
class SettingsPage extends ConsumerWidget {
  final String title;
  final Widget Function(AppSettings settings) body;

  const SettingsPage({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (ref.watch(settingsProvider)) {
        AsyncValue(:final value?) => body(value),
        AsyncError() => EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'સેટિંગ્સ લોડ ન થયા',
            message: 'ફરી પ્રયત્ન કરો · Please try again',
            actionLabel: 'ફરી પ્રયત્ન કરો',
            onAction: () => ref.invalidate(settingsProvider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Saves a settings change, telling the user if it could not be stored.
void saveSettings(BuildContext context, SettingsNotifier notifier,
    AppSettings Function(AppSettings) change) {
  notifier.edit(change).catchError((Object _) {
    if (context.mounted) {
      showAppSnack(context, 'સેવ ન થયું · Could not save settings',
          type: SnackType.error);
    }
  });
}

class SettingsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;

  const SettingsField(this.controller, this.label, this.hint, this.onChanged,
      {super.key, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboard,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}

class SettingsToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle(this.title, this.subtitle, this.value, this.onChanged,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// A round colour choice with a check mark when selected.
class ColorSwatchButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final Widget? child;

  const ColorSwatchButton({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.fast),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? context.colors.onSurface : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : child,
      ),
    );
  }
}
