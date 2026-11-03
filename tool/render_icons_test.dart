// Renders the launcher icon sources from BrandMarkPainter:
//
//   flutter test tool/render_icons_test.dart && dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;

import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;

/// The launcher icons use the default palette, whatever the phone's theme.
final _brand =
    BrandColors.of(ColorScheme.fromSeed(seedColor: AppColor.navy.seed));

void main() {
  testWidgets('render launcher icons', (tester) async {
    await tester.runAsync(() async {
      // Full icon (iOS, web, pre-Android 8): the mark on the brand gradient.
      await _render('assets/icon/icon.png', (canvas) {
        canvas.drawRect(
          Offset.zero & const Size.square(_size),
          Paint()
            ..shader = ui.Gradient.linear(Offset.zero,
                const Offset(_size, _size), [_brand.heroEnd, _brand.heroStart]),
        );
        _mark(canvas, scale: 0.8, fill: _brand);
      });
      // Adaptive icon layers; the launcher adds the background colour and
      // the safe-zone inset.
      await _render('assets/icon/icon_foreground.png',
          (canvas) => _mark(canvas, scale: 0.96, fill: _brand));
      await _render(
          'assets/icon/icon_monochrome.png',
          (canvas) =>
              _mark(canvas, scale: 0.96, fill: null, gold: Colors.white));
    });
    // ignore: avoid_print
    print('Adaptive icon background: #${_hex(_brand.heroStart)}');
  });
}

void _mark(Canvas canvas,
    {required double scale,
    required BrandColors? fill,
    Color gold = brandGold}) {
  final side = _size * scale;
  final inset = (_size - side) / 2;
  canvas
    ..save()
    ..translate(inset, inset);
  BrandMarkPainter(fill: fill, gold: gold).paint(canvas, Size.square(side));
  canvas.restore();
}

Future<void> _render(String path, void Function(Canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image =
      await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).writeAsBytes(png!.buffer.asUint8List());
  image.dispose();
}

String _hex(Color color) => (color.toARGB32() & 0xFFFFFF)
    .toRadixString(16)
    .padLeft(6, '0')
    .toUpperCase();
