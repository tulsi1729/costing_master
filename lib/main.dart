import 'package:costing_master/screens/splash_screen.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/storage/image_storage.dart';
import 'package:costing_master/storage/local_db.dart';
import 'package:costing_master/sync/sync_notifier.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final localDb = await LocalDb.open();
  await LocalImages.init();
  runApp(ProviderScope(
    overrides: [localDbProvider.overrideWithValue(localDb)],
    child: const CostingMasterApp(),
  ));
}

class CostingMasterApp extends ConsumerWidget {
  const CostingMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps background sync alive for the whole session without rebuilding.
    ref.listen(syncProvider, (_, __) {});
    final color = ref.watch(appColorProvider);
    return DynamicColorBuilder(
      builder: (light, dark) => MaterialApp(
        title: 'Costing Master',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(color, wallpaper: light?.primary),
        darkTheme: AppTheme.dark(color, wallpaper: dark?.primary),
        themeMode: ref.watch(themeModeProvider),
        navigatorObservers: [_DismissKeyboardOnNavigate()],
        home: const SplashScreen(),
      ),
    );
  }
}

/// Closes the keyboard whenever a screen, sheet or dialog opens or closes.
/// Otherwise a field that had focus keeps the keyboard up after saving, or
/// gets focus back (and reopens it) when the user returns to its screen.
class _DismissKeyboardOnNavigate extends NavigatorObserver {
  void _dismiss() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _dismiss();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _dismiss();
}
