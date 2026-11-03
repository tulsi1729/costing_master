import 'dart:ui' as ui;

import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:flutter/material.dart';

/// The logo keeps its own gold whatever app theme is chosen.
const brandGold = Color(0xFFC9A227);

/// The app's mark: one bold ક on a rounded tile, in the spirit of a single
/// letter app icon. Its crossbar is a gold baguette-cut diamond set into the
/// letter, and the lower bowl runs off the bottom edge of the tile.
///
/// Drawn in code so it stays crisp at any size and costs no asset bytes; the
/// launcher icons are rendered from it too (see `tool/render_icons_test.dart`).
/// With [animate], the tile pops in, the letter rises, the diamond slides
/// into its setting and a light sweeps across, in under a second.
class BrandMark extends StatefulWidget {
  final double size;
  final bool animate;

  const BrandMark({super.key, this.size = 96, this.animate = false});

  /// Length of the [animate] sequence.
  static const animationDuration = Duration(milliseconds: 900);

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

/// Paints the brand mark at animation [progress] (1 is the finished mark).
///
/// With [tile] false the letter is drawn without its tile, and its bowl
/// overflows the bottom of the paint area instead of being clipped: the
/// adaptive launcher icon layers rely on the launcher's mask for the bleed.
/// With [fill] null it draws a one-colour silhouette in [gold], with the
/// diamond's setting knocked out: the layer Android tints for themed icons.
class BrandMarkPainter extends CustomPainter {
  final double progress;
  final Color gold;
  final BrandColors? fill;
  final bool tile;

  const BrandMarkPainter({
    this.progress = 1,
    this.gold = brandGold,
    required this.fill,
    this.tile = true,
  });

  static const _ivory = Color(0xFFF7F1E1);

  /// The letter's size and position: font units to the tile's side, and
  /// the baseline's offset from the tile's top-left corner as fractions of
  /// the side. The baseline sits below the tile, so the bowl bleeds off it.
  static const _unit = 0.0007;
  static const _originX = 0.092;
  static const _originY = 1.05;

  /// The baguette diamond across the letter, in font units.
  static const _gemTopLeft = Offset(40, 642);
  static const _gemTopRight = Offset(1120, 848);
  static const _gemBottomRight = Offset(1120, 592);
  static const _gemBottomLeft = Offset(40, 386);

  /// [progress] within the part of the timeline from [begin] to [end].
  double _phase(double begin, double end, Curve curve) =>
      curve.transform(((progress - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final fill = this.fill;
    final square = Rect.fromCenter(center: c, width: s, height: s);
    final tilePath = Path()
      ..addRRect(RRect.fromRectAndRadius(square, Radius.circular(s * 0.225)));
    final withTile = tile && fill != null;

    // Pops in slightly larger than its final size and settles.
    final pop = _phase(0, 0.45, Curves.easeOutBack);
    final scale = 0.85 + 0.15 * pop;
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..scale(scale)
      ..translate(-c.dx, -c.dy);

    if (withTile) {
      final fillIn = _phase(0, 0.3, Curves.easeOut);
      canvas.drawPath(
        tilePath,
        Paint()
          ..shader = ui.Gradient.linear(square.topLeft, square.bottomRight, [
            fill.heroEnd.withValues(alpha: fillIn),
            fill.heroStart.withValues(alpha: fillIn),
          ]),
      );
      // Satin light from the top-left corner.
      canvas.drawPath(
        tilePath,
        Paint()
          ..shader = ui.Gradient.linear(
            square.topLeft,
            Offset.lerp(square.topLeft, square.bottomRight, 0.6)!,
            [
              Colors.white.withValues(alpha: 0.12 * fillIn),
              Colors.white.withValues(alpha: 0),
            ],
          ),
      );
      canvas
        ..save()
        ..clipPath(tilePath);
    }

    // The letter, in font units with y pointing up.
    canvas
      ..save()
      ..translate(square.left + s * _originX, square.top + s * _originY)
      ..scale(s * _unit, -s * _unit);

    final rise = _phase(0.2, 0.6, Curves.easeOutCubic);
    final slide = _phase(0.45, 0.8, Curves.easeOutCubic);
    if (fill == null) {
      _paintSilhouette(canvas, rise, slide);
    } else {
      _paintLetter(canvas, fill, rise, slide);
    }
    canvas.restore();

    if (withTile) {
      // One light sweep across the finished mark.
      final sweep = _phase(0.7, 1, Curves.easeInOut);
      if (sweep > 0 && sweep < 1) {
        final x = c.dx - s + sweep * s * 2;
        canvas.drawRect(
          square,
          Paint()
            ..shader = ui.Gradient.linear(
              Offset(x - s * 0.25, c.dy - s * 0.25),
              Offset(x + s * 0.25, c.dy + s * 0.25),
              [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0),
              ],
              const [0, 0.5, 1],
            ),
        );
      }
      canvas.restore();

      // A hairline of gold around the tile.
      canvas.drawPath(
        tilePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.008
          ..color =
              gold.withValues(alpha: 0.4 * _phase(0.1, 0.5, Curves.easeOut)),
      );
    }
    canvas.restore();
  }

  void _paintLetter(
      Canvas canvas, BrandColors fill, double rise, double slide) {
    if (rise > 0) {
      canvas.drawPath(
        _body.shift(Offset(0, -(1 - rise) * 120)),
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 1240),
            const Offset(0, -30),
            [Colors.white, _ivory]
                .map((c) => c.withValues(alpha: rise))
                .toList(),
          ),
      );
    }
    if (slide <= 0) return;

    canvas
      ..save()
      ..translate(-(1 - slide) * 300, -(1 - slide) * 57);
    final outline = _gemOutline();
    // The setting: a dark gap that sinks the diamond into the letter.
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 48
        ..strokeJoin = StrokeJoin.round
        ..color = fill.heroStart.withValues(alpha: slide),
    );
    final table = _gemTable();
    Color shade(double t) => (t > 0
            ? Color.lerp(gold, Colors.white, t)!
            : Color.lerp(gold, Colors.black, -t)!)
        .withValues(alpha: slide);
    // Step-cut facets: light from above, shadow below.
    final facets = [
      ([_gemTopLeft, _gemTopRight, table[1], table[0]], 0.45),
      ([_gemTopRight, _gemBottomRight, table[2], table[1]], 0.22),
      ([_gemBottomRight, _gemBottomLeft, table[3], table[2]], -0.28),
      ([_gemBottomLeft, _gemTopLeft, table[0], table[3]], -0.1),
    ];
    for (final (points, t) in facets) {
      canvas.drawPath(
        Path()..addPolygon(points, true),
        Paint()..color = shade(t),
      );
    }
    canvas.drawPath(
      Path()..addPolygon(table, true),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(200, 700),
          const Offset(1000, 450),
          [shade(0.25), shade(0.75), shade(0.05), shade(0)],
          const [0, 0.45, 0.55, 1],
        ),
    );
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.white.withValues(alpha: 0.45 * slide),
    );
    canvas.restore();
  }

  /// One colour throughout: the setting and the diamond's table are cut out
  /// so the crossbar still reads as a stone.
  void _paintSilhouette(Canvas canvas, double rise, double slide) {
    final colour = Paint()..color = gold.withValues(alpha: rise);
    final cut = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..saveLayer(null, Paint())
      ..drawPath(_body.shift(Offset(0, -(1 - rise) * 120)), colour);
    if (slide > 0) {
      final outline = _gemOutline();
      canvas
        ..save()
        ..translate(-(1 - slide) * 300, -(1 - slide) * 57)
        ..drawPath(outline, cut..strokeWidth = 48)
        ..drawPath(outline, Paint()..color = gold.withValues(alpha: slide))
        ..drawPath(Path()..addPolygon(_gemTable(), true), cut..strokeWidth = 20)
        ..restore();
    }
    canvas.restore();
  }

  static Path _gemOutline() => Path()
    ..addPolygon(
        [_gemTopLeft, _gemTopRight, _gemBottomRight, _gemBottomLeft], true);

  /// The flat top of the stone, inset from the outline: top-left, top-right,
  /// bottom-right, bottom-left.
  static List<Offset> _gemTable() {
    const dx = 70.0, dy = 52.0;
    return [
      _gemTopLeft + const Offset(dx, -dy),
      _gemTopRight + const Offset(-dx, -dy),
      _gemBottomRight + const Offset(-dx, dy),
      _gemBottomLeft + const Offset(dx, dy),
    ];
  }

  /// ક without its crossbar: the upper hook and the lower bowl, from Anek
  /// Gujarati ExtraBold (SIL Open Font License), in font units.
  static final Path _body = Path()
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
    ..close();

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.progress != progress ||
      old.gold != gold ||
      old.fill != fill ||
      old.tile != tile;
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
