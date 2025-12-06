import 'dart:developer';

import 'package:costing_master/common/enums.dart';
import 'package:costing_master/constants.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/widgets/my_answer.dart';
import 'package:costing_master/widgets/my_text_field.dart';
import 'package:flutter/material.dart';

class DiamondsRateRow extends StatefulWidget {
  final PartType partType;
  final DiamondType diamondType;
  final DiamondCosting? diamondCosting;
  final void Function(double, DiamondCosting) onChanged;
  const DiamondsRateRow({
    super.key,
    required this.partType,
    required this.diamondType,
    required this.onChanged,
    this.diamondCosting,
  });

  @override
  State<DiamondsRateRow> createState() => _DiamondsRateRowState();
}

class _DiamondsRateRowState extends State<DiamondsRateRow> {
  Map<PartType, String> partNameMap = {
    PartType.buta: "બુટા",
    PartType.patti: "પટ્ટી",
  };

  Map<DiamondType, String> diamondNameMap = {
    DiamondType.shadow: "shadow ડાયમંડ",
    DiamondType.color: "color ડાયમંડ",
    DiamondType.jarkan: "jarkan ડાયમંડ",
    DiamondType.dmc: "dmc ડાયમંડ",
  };

  static double n = 100;
  late final TextEditingController diamondsPerElementController;
  late final TextEditingController elementsCountController;
  late final TextEditingController diamondsRateController;
  double totalSum = 0;

  @override
  void initState() {
    super.initState();
    String? diamondRate = widget.diamondCosting?.diamondRate == null
        ? null
        : (widget.diamondCosting?.diamondRate ?? 0 * n).toString();
    diamondsPerElementController = TextEditingController(
        text: widget.diamondCosting?.diamondsPerPart.toString());
    elementsCountController = TextEditingController(
        text: widget.diamondCosting?.numbersOfPartsPerSari.toString());

    diamondsRateController = TextEditingController(text: diamondRate);

    if (widget.diamondCosting == null) {
      null;
    } else {
      totalSum = (widget.diamondCosting!.diamondsPerPart *
          widget.diamondCosting!.numbersOfPartsPerSari *
          widget.diamondCosting!.diamondRate);
    }

    log(widget.diamondCosting.toString(), name: "init rate row");
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyTextField(
          labelText:
              'એક ${partNameMap[widget.partType]} માં ${diamondNameMap[widget.diamondType]} ની સંખ્યા',
          onChanged: onChangedInput,
          controller: diamondsPerElementController,
        ),
        const Text(" x "),
        MyTextField(
          labelText: '${partNameMap[widget.partType]} ની સંખ્યા',
          onChanged: onChangedInput,
          controller: elementsCountController,
        ),
        const Text(" x "),
        MyTextField(
          labelText: '$n ડાયમંડ ભાવ',
          suffixText: inrSymbol,
          onChanged: onChangedInput,
          controller: diamondsRateController,
        ),
        const Text(" = "),
        MyAnswer(answer: totalSum),
      ],
    );
  }

  void onChangedInput(String _) {
    int diamondsPerElement =
        int.tryParse(diamondsPerElementController.text) ?? 0;
    double elementsCount = double.tryParse(elementsCountController.text) ?? 0;
    double oneDiamondsRate =
        ((double.tryParse(diamondsRateController.text) ?? 0) / n);

    setState(() {
      totalSum = (diamondsPerElement * elementsCount * oneDiamondsRate);
    });
    widget.onChanged(
      totalSum,
      DiamondCosting(
          diamondType: widget.diamondType,
          diamondRate: oneDiamondsRate,
          diamondsPerPart: diamondsPerElement,
          numbersOfPartsPerSari: elementsCount,
          partType: widget.partType),
    );
  }
}
