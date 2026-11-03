import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:costing_master/sync/sync_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

/// Business profile, quote style and theme, stored on this phone and backed
/// up to `users/{uid}` once the user signs in.
class SettingsNotifier extends AsyncNotifier<AppSettings> {
  late LocalDb _local;

  @override
  Future<AppSettings> build() async {
    _local = ref.watch(localDbProvider);
    final map =
        await _local.settings.record(LocalDb.settingsKey).get(_local.db);
    return AppSettings.fromMap(map);
  }

  AppSettings get current => state.value ?? const AppSettings();

  /// Applies the change locally right away, then persists it.
  Future<void> save(AppSettings settings) async {
    final previous = state.value;
    state = AsyncData(settings);
    try {
      await _local.settings
          .record(LocalDb.settingsKey)
          .put(_local.db, LocalDb.dirty(settings.toMap()));
      if (ref.mounted) ref.read(syncProvider.notifier).syncSoon();
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> edit(AppSettings Function(AppSettings) change) =>
      save(change(state.value ?? const AppSettings()));
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final themeModeProvider = Provider<ThemeMode>((ref) => ref.watch(
    settingsProvider.select((s) => s.value?.themeMode ?? ThemeMode.system)));

final appColorProvider = Provider<AppColor>((ref) => ref.watch(
    settingsProvider.select((s) => s.value?.appColor ?? AppColor.system)));
