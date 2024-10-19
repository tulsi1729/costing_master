import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/preview_model.dart';
import 'package:costing_master/costings/costing_stepper/preview_screen.dart';
import 'package:flutter/material.dart';

class SeparatePreview extends StatelessWidget {
  final Costing costing;
  final String clientName;
  final PreviewModel previewModel;

  const SeparatePreview({
    super.key,
    required this.costing,
    required this.previewModel,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Preview(
      previewModel: previewModel,
      costing: costing,
      clientName: clientName,
    ));
  }
}
