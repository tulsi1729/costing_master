import 'package:costing_master/constants.dart';
import 'package:costing_master/widgets/my_answer.dart';
import 'package:costing_master/widgets/my_text_field.dart';
import 'package:flutter/material.dart';

class DiamondsRateRow extends StatefulWidget {
  final String elementName;
  final void Function(double) onChanged;
  const DiamondsRateRow({
    super.key,
    required this.elementName,
    required this.onChanged,
  });

  @override
  State<DiamondsRateRow> createState() => _DiamondsRateRowState();
}

class _DiamondsRateRowState extends State<DiamondsRateRow> {
  static int n = 100;
  TextEditingController diamondsPerElementController = TextEditingController();
  TextEditingController elementsCountController = TextEditingController();
  TextEditingController nDiamondsRateController = TextEditingController();
  double totalSum = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyTextField(
          labelText: 'એક ${widget.elementName} માં ડાયમંડ',
          onChanged: onChangedInput,
          controller: diamondsPerElementController,
        ),
        const Text(" x "),
        MyTextField(
          labelText: '${widget.elementName} ની સંખ્યા',
          onChanged: onChangedInput,
          controller: elementsCountController,
        ),
        const Text(" x "),
        MyTextField(
          labelText: '$n ડાયમંડ ભાવ',
          suffixText: inrSymbol,
          onChanged: onChangedInput,
          controller: nDiamondsRateController,
        ),
        const Text(" = "),
        MyAnswer(answer: totalSum),
      ],
    );
  }

  void onChangedInput(String _) {
    double diamondsPerElement =
        double.tryParse(diamondsPerElementController.text) ?? 0;
    double elementsCount = double.tryParse(elementsCountController.text) ?? 0;
    double oneDiamondsRate =
        (double.tryParse(nDiamondsRateController.text) ?? 0) / n;

    setState(() {
      totalSum = (diamondsPerElement * elementsCount * oneDiamondsRate);
    });
    widget.onChanged(totalSum);
  }
}
