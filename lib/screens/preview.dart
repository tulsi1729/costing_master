import 'package:costing_master/model/info_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Preview extends ConsumerStatefulWidget {
  final InfoModel? info;

  const Preview({super.key, required this.info});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PreviewState();
}

class _PreviewState extends ConsumerState<Preview> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Column(
            children: (widget.info != null)
                ? [
                    Text(
                        "Client Name :  ${widget.info!.clientName.toString()}"),
                    Text("Sari Name : ${widget.info!.sariName.toString()}"),
                    Text("Design No. : ${widget.info!.designNo.toString()}"),
                    Image.network(
                      widget.info!.imageUrl.toString(),
                      height: 200,
                    ),
                  ]
                : [],
          ),
        ],
      ),
    );
  }
}
