import 'package:costing_master/common/enums.dart';
import 'package:costing_master/constants.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/widgets/my_answer.dart';
import 'package:costing_master/widgets/my_text_field.dart';
import 'package:flutter/material.dart';

class DiamondsRateRow extends StatefulWidget {
  final PartType partType;
  final DiamondType diamondType;
  final void Function(double, DiamondCosting) onChanged;
  const DiamondsRateRow({
    super.key,
    required this.partType,
    required this.diamondType,
    required this.onChanged,
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

  static int n = 100;
  TextEditingController diamondsPerElementController = TextEditingController();
  TextEditingController elementsCountController = TextEditingController();
  TextEditingController diamondsRateController = TextEditingController();
  double totalSum = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyTextField(
          labelText:
              'એક ${partNameMap[widget.partType]} માં ${widget.diamondType}',
          onChanged: onChangedInput,
          controller: diamondsPerElementController,
        ),
        const Text(" x "),
        MyTextField(
          labelText: '${widget.partType} ની સંખ્યા',
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
        (double.tryParse(diamondsRateController.text) ?? 0) / n;

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
            partType: widget.partType));
    // log("diamond $totalSum.toString()");
  }
}
