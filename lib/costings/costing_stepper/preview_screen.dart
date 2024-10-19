import 'package:costing_master/costings/notifier/selected_client_notifier.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/preview_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class Preview extends ConsumerStatefulWidget {
  final Costing? costing;
  final PreviewModel previewModel;
  final String clientName;

  const Preview({
    super.key,
    required this.costing,
    required this.previewModel,
    required this.clientName,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<Preview> {
  late final TextEditingController shadowDiamondCosting;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey globalKey = GlobalKey();

    showPicker() async {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await (image.toByteData(format: ui.ImageByteFormat.png));
      if (byteData != null) {
        final result = await ImageGallerySaver.saveImage(
            quality: 100, byteData.buffer.asUint8List());
      }
    }

    List<Widget> tableRowWidgets = [];

    widget.previewModel.previewMap.forEach(
      (chargeType, previewRowModel) {
        tableRowWidgets.add(
          Table(
              border: TableBorder
                  .all(), // Allows to add a border decoration around your table
              children: [
                TableRow(children: [
                  Text(
                    previewRowModel.title,
                  ),
                  Text(
                    previewRowModel.charge,
                  ),
                  Text(
                    previewRowModel.totalCharge,
                  ),
                ]),
              ]),
        );
      },
    );
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              RepaintBoundary(
                key: globalKey,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: widget.costing != null
                              ? [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Sari Name",
                                          style: TextStyle(fontSize: 15)),
                                      Text(
                                        widget.costing!.sariName.toString(),
                                        style: const TextStyle(fontSize: 25),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    children: [
                                      const Text("Design No.",
                                          style: TextStyle(fontSize: 15)),
                                      Text(widget.costing!.designNo.toString(),
                                          style: const TextStyle(fontSize: 25)),
                                    ],
                                  ),
                                ]
                              : [],
                        ),
                        subtitle: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: widget.costing != null
                              ? [
                                  Text(ref.read(selectedClientProvider)!.name,
                                      style: const TextStyle(fontSize: 23)),
                                  Center(
                                    child: Image.network(
                                      widget.costing!.imageUrl,
                                      height: 200,
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      Table(
                        border: TableBorder
                            .all(), // Allows to add a border decoration around your table
                        children: const [
                          TableRow(children: [
                            Text('Items'),
                            Text('Rate'),
                            Text('Total'),
                          ]),
                        ],
                      ),
                      ...tableRowWidgets,
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        showPicker();
                      },
                      child: const Text("SAVE IMAGE")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
