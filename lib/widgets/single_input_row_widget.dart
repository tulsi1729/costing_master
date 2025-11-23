import 'package:costing_master/constants.dart';
import 'package:costing_master/widgets/my_answer.dart';
import 'package:costing_master/widgets/my_text_field.dart';
import 'package:flutter/material.dart';

class SingleInputRow extends StatefulWidget {
  final String labelText;
    final double? initialValue;
  final String suffixText;

  final double? Function(double) onChanged;

  const SingleInputRow({
    super.key,
    required this.labelText,
    required this.onChanged,
    required this.initialValue,

    this.suffixText = inrSymbol,
  });

  @override
  State<SingleInputRow> createState() => SingleInputRowState();
}

class SingleInputRowState extends State<SingleInputRow> {
  double charges = 0;
  String selectedValue = "";
  late final TextEditingController  controller;

 @override
void initState() {
  super.initState();
  // Initialize with existing value or empty string
  controller = TextEditingController(
    text: widget.initialValue != null && widget.initialValue! > 0
        ? widget.initialValue!.toString()
        : ''
  );
  charges = widget.initialValue ?? 0;
}
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyTextField(
          labelText: widget.labelText,
          suffixText: widget.suffixText,
          controller: controller,
          labelPadding: 4,
          onChanged: (value) {
            selectedValue = value;
            updateState();
          },
        ),
        const Text(" = "),
        MyAnswer(
          answer: charges,
        ),
        const SizedBox(
          height: 24,
        ),
      ],
    );
  }

  void updateState() {
    double charges = double.tryParse(selectedValue) ?? 0;
    setState(() {
      this.charges = widget.onChanged(charges) ?? charges ;
    });
  }

   
}
