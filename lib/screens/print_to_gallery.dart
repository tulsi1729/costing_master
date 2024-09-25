import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class PrintToGallery extends StatelessWidget {
  PrintToGallery({super.key});

  final GlobalKey _globalKey = GlobalKey();

  _showPicker() async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData =
        await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      final result = await ImageGallerySaver.saveImage(
          quality: 100, byteData.buffer.asUint8List());
      log(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showPicker();
      },
      child: RepaintBoundary(
        key: _globalKey,
        child: const Column(
          children: [
            Text("hello"),
            Column(
              children: [
                Row(
                  children: [
                    Text("costing master"),
                    Text("Save to Gallery"),
                    // માં ડાયમંડ
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}