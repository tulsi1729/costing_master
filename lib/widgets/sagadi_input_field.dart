import 'package:costing_master/common/enums.dart';
import 'package:costing_master/constants.dart';
import 'package:costing_master/model/sagadi_costing.dart';
import 'package:costing_master/widgets/my_answer.dart';
import 'package:costing_master/widgets/my_text_field.dart';
import 'package:flutter/material.dart';

class SagadiInputField extends StatefulWidget {
  final String labelText;
  final void Function(double, SagadiCosting) onChanged;
  const SagadiInputField({
    super.key,
    required this.labelText,
    required this.onChanged,
  });

  @override
  State<SagadiInputField> createState() => _SagadiInputFieldState();
}

class _SagadiInputFieldState extends State<SagadiInputField> {
  Map<SagadiItemType, String> sagadiTypeMap = {
    SagadiItemType.buta: 'buta',
    SagadiItemType.less: 'less',
    SagadiItemType.valiya: 'valiya',
  };

  TextEditingController elementsCountController = TextEditingController();
  TextEditingController oneElementRateController = TextEditingController();
  double totalSum = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyTextField(
          labelText: '${widget.labelText} ની સંખ્યા',
          onChanged: onChangedInput,
          controller: elementsCountController,
        ),
        const Text(" x "),
        MyTextField(
          labelText: '${widget.labelText} ની મજૂરી',
          suffixText: inrSymbol,
          onChanged: onChangedInput,
          controller: oneElementRateController,
        ),
        const Text(" = "),
        MyAnswer(answer: totalSum),
      ],
    );
  }

  void onChangedInput(String _) {
    double elementsCount = double.tryParse(elementsCountController.text) ?? 0;
    double oneElementRate = double.tryParse(oneElementRateController.text) ?? 0;

    setState(() {
      totalSum = elementsCount * oneElementRate;
    });
    widget.onChanged(
        totalSum,
        SagadiCosting(
          itemsCount: elementsCount,
          chargePerItem: oneElementRate,
        ));
  }
}
