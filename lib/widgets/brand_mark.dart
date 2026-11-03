import 'dart:ui' as ui;

import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/network_thumb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The logo keeps its own gold whatever app theme is chosen.
const brandGold = Color(0xFFC9A227);

/// The app's mark: a cut diamond, seen from the side, with ક set in its
/// pavilion. Gold girdle and facets on the theme's hero colours.
///
/// Drawn in code so it stays crisp at any size and costs no asset bytes; the
/// launcher icons are rendered from it too (see `tool/render_icons_test.dart`).
/// With [animate], the outline draws itself, the facets are cut one by one,
/// the stone fills, ક rises into it and a sparkle and a light sweep finish
/// it off.
class BrandMark extends StatefulWidget {
  final double size;
  final bool animate;

  const BrandMark({super.key, this.size = 96, this.animate = false});

  /// Length of the [animate] sequence.
  static const animationDuration = Duration(milliseconds: 1900);

  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BrandMark.animationDuration,
    value: widget.animate ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animate && !_controller.isAnimating && _controller.value == 0) {
      if (Motion.of(context, Motion.slow) == Duration.zero) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: BrandMarkPainter(
              progress: _controller.value,
              fill: context.brand,
            ),
          ),
        ),
      ),
    );
  }
}

/// The business's own logo when one is uploaded, otherwise the app's mark.
class AppLogo extends ConsumerWidget {
  final double size;

  const AppLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logo = ref
        .watch(settingsProvider.select((s) => s.value?.profile.logoUrl ?? ''));
    if (logo.isEmpty) return BrandMark(size: size);
    return ClipOval(
      child: SizedBox.square(dimension: size, child: NetworkThumb(url: logo)),
    );
  }
}

/// Paints the brand mark at animation [progress] (1 is the finished mark).
///
/// With [fill] null it draws only the outline, facets and letter in [gold]:
/// the one-colour layer Android tints for themed launcher icons.
class BrandMarkPainter extends CustomPainter {
  final double progress;
  final Color gold;
  final BrandColors? fill;

  const BrandMarkPainter({
    this.progress = 1,
    this.gold = brandGold,
    required this.fill,
  });

  static const _ivory = Color(0xFFF7F1E1);

  // The stone, as fractions of the side: the table (flat top), the girdle
  // (widest line) and the culet (bottom point).
  static const _tableY = 0.1, _tableLeft = 0.30, _tableRight = 0.70;
  static const _girdleY = 0.34, _girdleLeft = 0.04, _girdleRight = 0.96;
  static const _culet = Offset(0.5, 0.92);

  /// ક's size (side per font unit) and its baseline's position, as
  /// fractions of the side; it sits wholly inside the pavilion.
  static const _unit = 0.000245;
  static const _letterTop = 0.385;

  /// [progress] within the part of the timeline from [begin] to [end].
  double _phase(double begin, double end, Curve curve) =>
      curve.transform(((progress - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final o = size.center(Offset.zero) - Offset(s / 2, s / 2);
    Offset at(double x, double y) => o + Offset(x * s, y * s);
    final fill = this.fill;

    final tl = at(_tableLeft, _tableY), tr = at(_tableRight, _tableY);
    final gl = at(_girdleLeft, _girdleY), gr = at(_girdleRight, _girdleY);
    final culet = at(_culet.dx, _culet.dy);
    // Points along the girdle and the table, left to right.
    Offset girdle(double t) => Offset.lerp(gl, gr, t)!;
    Offset table(double t) => Offset.lerp(tl, tr, t)!;
    final outline = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(gr.dx, gr.dy)
      ..lineTo(culet.dx, culet.dy)
      ..lineTo(gl.dx, gl.dy)
      ..close();

    // Settles in from slightly smaller as it is drawn.
    final scale = 0.92 + 0.08 * _phase(0, 0.6, Curves.easeOutCubic);
    final c = size.center(Offset.zero);
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..scale(scale)
      ..translate(-c.dx, -c.dy);

    final fillIn = _phase(0.45, 0.7, Curves.easeOut);
    if (fill != null && fillIn > 0) {
      canvas.drawPath(
        outline,
        Paint()
          ..shader = ui.Gradient.linear(at(0, 0), at(1, 1), [
            fill.heroEnd.withValues(alpha: fillIn),
            fill.heroStart.withValues(alpha: fillIn),
          ]),
      );
      // Crown facets catch the light in turn, like a cut stone.
      final crown = [
        tl, girdle(0.25), table(1 / 3), girdle(0.5), table(2 / 3),
        girdle(0.75), tr, //
      ];
      for (var i = 0; i + 2 < crown.length; i++) {
        canvas.drawPath(
          Path()..addPolygon([crown[i], crown[i + 1], crown[i + 2]], true),
          Paint()
            ..color = Colors.white
                .withValues(alpha: (i.isEven ? 0.14 : 0.05) * fillIn),
        );
      }
      canvas
        ..drawPath(
          Path()..addPolygon([gl, girdle(0.25), tl], true),
          Paint()..color = Colors.white.withValues(alpha: 0.09 * fillIn),
        )
        ..drawPath(
          Path()..addPolygon([gr, girdle(0.75), tr], true),
          Paint()..color = Colors.black.withValues(alpha: 0.12 * fillIn),
        )
        // The pavilion's left half lit, its right half in shade.
        ..drawPath(
          Path()..addPolygon([gl, girdle(0.5), culet], true),
          Paint()
            ..shader = ui.Gradient.linear(gl, culet, [
              Colors.white.withValues(alpha: 0.1 * fillIn),
              Colors.white.withValues(alpha: 0),
            ]),
        )
        ..drawPath(
          Path()..addPolygon([girdle(0.5), gr, culet], true),
          Paint()..color = Colors.black.withValues(alpha: 0.12 * fillIn),
        );
    }

    // The facets are cut one after another.
    final facets = [
      (girdle(0), girdle(1)),
      (tl, girdle(0.25)),
      (girdle(0.25), table(1 / 3)),
      (table(1 / 3), girdle(0.5)),
      (girdle(0.5), table(2 / 3)),
      (table(2 / 3), girdle(0.75)),
      (girdle(0.75), tr),
      (girdle(0.25), culet),
      (girdle(0.75), culet),
    ];
    final facetPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round
      ..color = gold.withValues(alpha: fill == null ? 1 : 0.65);
    for (var i = 0; i < facets.length; i++) {
      final begin = 0.25 + i * 0.035;
      final t = _phase(begin, begin + 0.12, Curves.easeInOut);
      if (t <= 0) continue;
      final (a, b) = facets[i];
      canvas.drawLine(a, Offset.lerp(a, b, t)!, facetPaint);
    }

    // The gold outline traces itself.
    final trace = _phase(0, 0.35, Curves.easeInOutCubic);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = gold;
    if (trace >= 1) {
      canvas.drawPath(outline, edge);
    } else if (trace > 0) {
      for (final metric in outline.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * trace), edge);
      }
    }

    // ક rises into the pavilion.
    final letter = _phase(0.6, 0.8, Curves.easeOut);
    if (letter > 0) {
      final u = s * _unit;
      canvas
        ..save()
        ..translate(o.dx + s * 0.5 - u * 583,
            o.dy + s * _letterTop + u * 1239 + (1 - letter) * s * 0.05)
        ..scale(u, -u)
        ..drawPath(
          _letter,
          Paint()
            ..color = (fill == null ? gold : _ivory).withValues(alpha: letter),
        )
        ..restore();
    }

    if (fill != null) {
      // One light sweep across the stone, then a sparkle on the table.
      final sweep = _phase(0.78, 1, Curves.easeInOut);
      if (sweep > 0 && sweep < 1) {
        final x = o.dx - s * 0.5 + sweep * s * 2;
        canvas
          ..save()
          ..clipPath(outline)
          ..drawRect(
            o & Size.square(s),
            Paint()
              ..shader = ui.Gradient.linear(
                Offset(x - s * 0.25, o.dy),
                Offset(x + s * 0.25, o.dy + s * 0.5),
                [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0),
                ],
                const [0, 0.5, 1],
              ),
          )
          ..restore();
      }
      final twinkle = _phase(0.82, 1, Curves.linear);
      if (twinkle > 0) {
        // Flares, then settles to a small glint that stays.
        final glow = twinkle < 0.5
            ? Curves.easeOut.transform(twinkle * 2)
            : 1 - 0.45 * Curves.easeIn.transform((twinkle - 0.5) * 2);
        _sparkle(canvas, tr + Offset(-s * 0.02, s * 0.005), s * 0.09 * glow);
      }
    }
    canvas.restore();
  }

  /// A four-pointed star of [radius] centred on [c].
  static void _sparkle(Canvas canvas, Offset c, double radius) {
    final r = radius, w = radius * 0.18;
    final star = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + w, c.dy - w, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + w, c.dy + w, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - w, c.dy + w, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - w, c.dy - w, c.dx, c.dy - r)
      ..close();
    canvas
      ..drawCircle(
        c,
        r * 0.6,
        Paint()
          ..shader = ui.Gradient.radial(c, r * 0.6, [
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0),
          ]),
      )
      ..drawPath(star, Paint()..color = Colors.white);
  }

  /// ક from Anek Gujarati ExtraBold (SIL Open Font License), in font units
  /// with y pointing up: the upper hook, the lower bowl and the crossbar.
  static final Path _letter = Path()
    ..moveTo(459, 658)
    ..quadraticBezierTo(353, 660, 274, 689)
    ..quadraticBezierTo(195, 718, 152, 776)
    ..quadraticBezierTo(109, 833, 109, 919)
    ..lineTo(109, 928)
    ..quadraticBezierTo(109, 1082, 232, 1160)
    ..quadraticBezierTo(355, 1239, 593, 1239)
    ..quadraticBezierTo(695, 1239, 782, 1223)
    ..quadraticBezierTo(870, 1207, 929, 1185)
    ..lineTo(958, 911)
    ..quadraticBezierTo(895, 926, 822, 936)
    ..quadraticBezierTo(748, 946, 673, 946)
    ..quadraticBezierTo(562, 946, 517, 918)
    ..quadraticBezierTo(472, 891, 472, 844)
    ..lineTo(472, 840)
    ..quadraticBezierTo(472, 802, 509, 775)
    ..quadraticBezierTo(546, 748, 643, 741)
    ..close()
    ..moveTo(537, -29)
    ..quadraticBezierTo(413, -29, 312, -14)
    ..quadraticBezierTo(211, 1, 135, 22)
    ..lineTo(107, 308)
    ..quadraticBezierTo(191, 290, 282, 279)
    ..quadraticBezierTo(373, 268, 479, 268)
    ..quadraticBezierTo(581, 268, 632, 294)
    ..quadraticBezierTo(684, 320, 684, 376)
    ..lineTo(684, 380)
    ..quadraticBezierTo(684, 427, 652, 456)
    ..quadraticBezierTo(620, 484, 531, 493)
    ..lineTo(712, 569)
    ..quadraticBezierTo(871, 570, 960, 502)
    ..quadraticBezierTo(1049, 435, 1049, 307)
    ..lineTo(1049, 297)
    ..quadraticBezierTo(1049, 131, 912, 51)
    ..quadraticBezierTo(775, -29, 537, -29)
    ..close()
    // The crossbar.
    ..moveTo(50, 371)
    ..lineTo(50, 658)
    ..lineTo(511, 715)
    ..lineTo(705, 487)
    ..close()
    ..moveTo(440, 734)
    ..lineTo(1116, 861)
    ..lineTo(1116, 578)
    ..lineTo(536, 507)
    ..close();

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.progress != progress || old.gold != gold || old.fill != fill;
}

/// "કોસ્ટિંગ માસ્ટર" with a small English line underneath.
class BrandWordmark extends StatelessWidget {
  final Color? color;
  final double scale;

  const BrandWordmark({super.key, this.color, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'કોસ્ટિંગ માસ્ટર',
          style: TextStyle(
            fontSize: 30 * scale,
            fontWeight: FontWeight.w800,
            color: fg,
            height: 1.2,
          ),
        ),
        Text(
          'COSTING MASTER',
          style: TextStyle(
            fontSize: 11 * scale,
            letterSpacing: 4 * scale,
            fontWeight: FontWeight.w600,
            color: fg.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
