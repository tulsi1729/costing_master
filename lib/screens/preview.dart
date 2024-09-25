import 'package:costing_master/model/info_model.dart';
import 'package:flutter/material.dart';

class Preview extends StatefulWidget {
  final InfoModel? info;

  const Preview({super.key, required this.info});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: (widget.info != null)
            ? [
                Text("Client Name :  ${widget.info!.clientName.toString()}"),
                Text("Sari Name : ${widget.info!.sariName.toString()}"),
                Text("Design No. : ${widget.info!.designNo.toString()}"),
                Image.network(
                  widget.info!.imageUrl.toString(),
                  height: 200,
                ),
              ]
            : [],
      ),
    );
  }
}
