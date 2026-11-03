import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:animations/animations.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:flutter/material.dart';

/// Colours for the app's deep "hero" areas (home header, total bar, backup
/// sheet), derived from the colour scheme so they follow the chosen palette.
/// They stay dark in both light and dark mode, with white text on top.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  final Color heroStart;
  final Color heroEnd;

  /// For amounts, icons and buttons that sit on the hero gradient.
  final Color heroAccent;
  final Color onHeroAccent;

  const BrandColors({
    required this.heroStart,
    required this.heroEnd,
    required this.heroAccent,
    required this.onHeroAccent,
  });

  factory BrandColors.of(ColorScheme scheme) => BrandColors(
        heroStart: scheme.onPrimaryFixed,
        heroEnd: scheme.onPrimaryFixedVariant,
        heroAccent: scheme.primaryFixed,
        onHeroAccent: scheme.onPrimaryFixed,
      );

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [heroStart, heroEnd],
      );

  @override
  BrandColors copyWith({
    Color? heroStart,
    Color? heroEnd,
    Color? heroAccent,
    Color? onHeroAccent,
  }) =>
      BrandColors(
        heroStart: heroStart ?? this.heroStart,
        heroEnd: heroEnd ?? this.heroEnd,
        heroAccent: heroAccent ?? this.heroAccent,
        onHeroAccent: onHeroAccent ?? this.onHeroAccent,
      );

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      heroAccent: Color.lerp(heroAccent, other.heroAccent, t)!,
      onHeroAccent: Color.lerp(onHeroAccent, other.onHeroAccent, t)!,
    );
  }
}

extension BrandTheme on BuildContext {
  BrandColors get brand => Theme.of(this).extension<BrandColors>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

abstract final class AppTheme {
  /// [wallpaper] is the phone's own primary colour (Android 12+), used when
  /// [color] is [AppColor.system].
  static ThemeData light(AppColor color, {Color? wallpaper}) =>
      _build(Brightness.light, _seed(color, wallpaper));
  static ThemeData dark(AppColor color, {Color? wallpaper}) =>
      _build(Brightness.dark, _seed(color, wallpaper));

  static Color _seed(AppColor color, Color? wallpaper) =>
      color == AppColor.system && wallpaper != null ? wallpaper : color.seed;

  static ThemeData _build(Brightness brightness, Color seed) {
    final isDark = brightness == Brightness.dark;
    // Rebuilding the scheme from one seed keeps every role (surfaces,
    // containers, fixed colours) consistent, also for wallpaper colours.
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final brand = BrandColors.of(scheme);
    final radius = BorderRadius.circular(14);
    // Derive every custom text style from the platform typography so they all
    // share the same font family.
    final typography = Typography.material2021(colorScheme: scheme);
    final text = isDark ? typography.white : typography.black;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [brand],
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge!.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        hintStyle: text.bodyLarge!
            .copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge!
              .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge!
              .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        extendedTextStyle: text.labelLarge!
            .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
