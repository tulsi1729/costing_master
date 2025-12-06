import 'package:costing_master/common/enums.dart';
import 'package:costing_master/domain/enums.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/preview_table_row_model.dart';

class PreviewModel {
  final Map<ChargeType, PreviewTableRowModel> previewMap;

  PreviewModel({
    required Costing costing,
    required String clientName,
  }) : previewMap = _getPreviewMap(costing);

  static Map<ChargeType, PreviewTableRowModel> _getPreviewMap(Costing costing) {
    Map<ChargeType, PreviewTableRowModel> previewMap = {};
    double grandTotal = 0;

    if (costing.diamondCostingsMap != null) {
      if (costing.diamondCostingsMap![PartType.buta]?[DiamondType.shadow] !=
          null) {
        double tempTotal = costing
                .diamondCostingsMap![PartType.buta]![DiamondType.shadow]!
                .diamondRate *
            costing.diamondCostingsMap![PartType.buta]![DiamondType.shadow]!
                .diamondsPerPart;

        previewMap[ChargeType.butaShadowDiamond] = PreviewTableRowModel(
            title:
                ("બુટા shadow ${costing.diamondCostingsMap![PartType.buta]![DiamondType.shadow]!.diamondsPerPart}"),
            charge: costing
                .diamondCostingsMap![PartType.buta]![DiamondType.shadow]!
                .diamondRate
                .toString(),
            totalCharge: tempTotal.toString());
        grandTotal += tempTotal;
      }
      if (costing.diamondCostingsMap![PartType.buta]?[DiamondType.color] !=
          null) {
        double tempTotal = costing
                .diamondCostingsMap![PartType.buta]![DiamondType.color]!
                .diamondRate *
            costing.diamondCostingsMap![PartType.buta]![DiamondType.color]!
                .diamondsPerPart;

        previewMap[ChargeType.butaColorDiamond] = PreviewTableRowModel(
          title:
              ("બુટા color ${costing.diamondCostingsMap![PartType.buta]![DiamondType.color]!.diamondsPerPart}"),
          charge: costing
              .diamondCostingsMap![PartType.buta]![DiamondType.color]!
              .diamondRate
              .toString(),
          totalCharge: tempTotal.toString(),
        );
        grandTotal += tempTotal;
      }

      if (costing.diamondCostingsMap![PartType.buta]?[DiamondType.jarkan] !=
          null) {
        double tempTotal = costing
                .diamondCostingsMap![PartType.buta]![DiamondType.jarkan]!
                .diamondRate *
            costing.diamondCostingsMap![PartType.buta]![DiamondType.jarkan]!
                .diamondsPerPart;

        previewMap[ChargeType.butaJarkan] = PreviewTableRowModel(
            title:
                ("બુટા jarkan ${costing.diamondCostingsMap![PartType.buta]![DiamondType.jarkan]!.diamondsPerPart}"),
            charge: costing
                .diamondCostingsMap![PartType.buta]![DiamondType.jarkan]!
                .diamondRate
                .toString(),
            totalCharge: tempTotal.toString());
        grandTotal += tempTotal;
      }

      if (costing.diamondCostingsMap![PartType.buta]?[DiamondType.dmc] !=
          null) {
        double tempTotal = costing
                .diamondCostingsMap![PartType.buta]![DiamondType.dmc]!
                .diamondRate *
            costing.diamondCostingsMap![PartType.buta]![DiamondType.dmc]!
                .diamondsPerPart;

        previewMap[ChargeType.butaDMC] = PreviewTableRowModel(
            title:
                ("બુટા dmc ${costing.diamondCostingsMap![PartType.buta]![DiamondType.dmc]!.diamondsPerPart}"),
            charge: costing
                .diamondCostingsMap![PartType.buta]![DiamondType.dmc]!
                .diamondRate
                .toString(),
            totalCharge: tempTotal.toString());
        grandTotal += tempTotal;
      }

      if (costing.diamondCostingsMap![PartType.patti]?[DiamondType.shadow] !=
          null) {
        double tempTotal = costing
                .diamondCostingsMap![PartType.patti]![DiamondType.shadow]!
                .diamondRate *
            costing.diamondCostingsMap![PartType.patti]![DiamondType.shadow]!
                .diamondsPerPart;

        previewMap[ChargeType.patiShadowDiamond] = PreviewTableRowModel(
            title:
                ("પટ્ટી Shadow ${costing.diamondCostingsMap![PartType.patti]![DiamondType.shadow]!.diamondsPerPart}"),
            charge: costing
                .diamondCostingsMap![PartType.patti]![DiamondType.shadow]!
                .diamondRate
                .toString(),
            totalCharge: tempTotal.toString());
        grandTotal += tempTotal;
      }

      if (costing.diamondCostingsMap![PartType.patti]?[DiamondType.color] !=
          null) {
        double tempTotal = costing
                .diamondCostingsMap![PartType.patti]![DiamondType.color]!
                .diamondRate *
            costing.diamondCostingsMap![PartType.patti]![DiamondType.color]!
                .diamondsPerPart;

        previewMap[ChargeType.patiColorDiamond] = PreviewTableRowModel(
            title:
                ("પટ્ટી color ${costing.diamondCostingsMap![PartType.patti]![DiamondType.color]!.diamondsPerPart}"),
            charge: costing
                .diamondCostingsMap![PartType.patti]![DiamondType.color]!
                .diamondRate
                .toString(),
            totalCharge: tempTotal.toString());
        grandTotal += tempTotal;
      }

      if (costing.diamondCostingsMap![PartType.patti]?[DiamondType.jarkan] !=
          null) {
        double tempTotal = costing
                .diamondCostingsMap![PartType.patti]![DiamondType.jarkan]!
                .diamondRate *
            costing.diamondCostingsMap![PartType.patti]![DiamondType.jarkan]!
                .diamondsPerPart;

        previewMap[ChargeType.patiJarkan] = PreviewTableRowModel(
            title:
                ("પટ્ટી jarkan ${costing.diamondCostingsMap![PartType.patti]![DiamondType.jarkan]!.diamondsPerPart}"),
            charge: costing
                .diamondCostingsMap![PartType.patti]![DiamondType.jarkan]!
                .diamondRate
                .toString(),
            totalCharge: tempTotal.toString());
        grandTotal += tempTotal;
      }

      if (costing.diamondCostingsMap![PartType.patti]?[DiamondType.dmc] !=
          null) {
        double tempTotal = costing
                .diamondCostingsMap![PartType.patti]![DiamondType.dmc]!
                .diamondRate *
            costing.diamondCostingsMap![PartType.patti]![DiamondType.dmc]!
                .diamondsPerPart;

        previewMap[ChargeType.patiDMC] = PreviewTableRowModel(
            title:
                ("પટ્ટી dmc ${costing.diamondCostingsMap![PartType.patti]![DiamondType.dmc]!.diamondsPerPart}"),
            charge: costing
                .diamondCostingsMap![PartType.patti]![DiamondType.dmc]!
                .diamondRate
                .toString(),
            totalCharge: tempTotal.toString());
        grandTotal += tempTotal;
      }
    }

    if (costing.sagadiCostingsMap != null) {
      if (costing.sagadiCostingsMap![SagadiItemType.buta] != null) {
        double tempTotal =
            costing.sagadiCostingsMap![SagadiItemType.buta]!.itemsCount *
                costing.sagadiCostingsMap![SagadiItemType.buta]!.chargePerItem;

        previewMap[ChargeType.butaSagadiCharges] = PreviewTableRowModel(
          title:
              ("સગડી બુટા  ${costing.sagadiCostingsMap![SagadiItemType.buta]!.itemsCount.toString()}"),
          charge: costing.sagadiCostingsMap![SagadiItemType.buta]!.chargePerItem
              .toString(),
          totalCharge: tempTotal.toString(),
        );
      }

      if (costing.sagadiCostingsMap![SagadiItemType.less] != null) {
        double tempTotal =
            costing.sagadiCostingsMap![SagadiItemType.less]!.itemsCount *
                costing.sagadiCostingsMap![SagadiItemType.less]!.chargePerItem;

        previewMap[ChargeType.lessSagadiCharges] = PreviewTableRowModel(
          title:
              ("સગડી લેસ  ${costing.sagadiCostingsMap![SagadiItemType.less]!.itemsCount.toString()}"),
          charge: costing.sagadiCostingsMap![SagadiItemType.less]!.chargePerItem
              .toString(),
          totalCharge: tempTotal.toString(),
        );
      }

      if (costing.sagadiCostingsMap![SagadiItemType.valiya] != null) {
        double tempTotal = costing
                .sagadiCostingsMap![SagadiItemType.valiya]!.itemsCount *
            costing.sagadiCostingsMap![SagadiItemType.valiya]!.chargePerItem;

        previewMap[ChargeType.valiyaSagadiCharges] = PreviewTableRowModel(
          title:
              ("સગડી વળીયા  ${costing.sagadiCostingsMap![SagadiItemType.valiya]!.itemsCount.toString()}"),
          charge: costing
              .sagadiCostingsMap![SagadiItemType.valiya]!.chargePerItem
              .toString(),
          totalCharge: tempTotal.toString(),
        );
      }
    }

    previewMap[ChargeType.sheetCharges] = PreviewTableRowModel(
      title: "સીટ ભરવાના",
      charge: costing.sheetBharvana.toString(),
      totalCharge: costing.sheetBharvana.toString(),
    );
    grandTotal += costing.sheetBharvana;

    previewMap[ChargeType.lessFiting] = PreviewTableRowModel(
      title: "લેસ ફીટીંગ",
      charge: costing.lessFiting.toString(),
      totalCharge: costing.lessFiting.toString(),
    );
    grandTotal += costing.lessFiting;

    previewMap[ChargeType.reniyaCutting] = PreviewTableRowModel(
      title: "રેણીયા કટીંગ",
      charge: costing.reniyaCutting.toString(),
      totalCharge: costing.reniyaCutting.toString(),
    );
    grandTotal += costing.reniyaCutting;

    previewMap[ChargeType.fusing] = PreviewTableRowModel(
      title: "ફ્યુઝિંગ",
      charge: costing.fusing.toString(),
      totalCharge: costing.fusing.toString(),
    );
    grandTotal += costing.fusing;

    previewMap[ChargeType.dieKapvana] = PreviewTableRowModel(
      title: "ડાય કાપવાના",
      charge: costing.dieKapvana.toString(),
      totalCharge: costing.dieKapvana.toString(),
    );
    grandTotal += costing.dieKapvana;

    previewMap[ChargeType.otherCharges] = PreviewTableRowModel(
      title: "અન્ય ખર્ચ",
      charge: costing.otherCost.toString(),
      totalCharge: costing.otherCost.toString(),
    );
    grandTotal += costing.otherCost;

    previewMap[ChargeType.totalCharges] = PreviewTableRowModel(
      title: "Total",
      charge: costing.totalExpense.toString(),
      totalCharge: costing.totalExpense.toString(),
    );
    grandTotal += costing.totalExpense;

    // double vatavAmount =
    //     (costing.totalExpense * (costing.vatavPercentage ?? 0)) / 100;
    // previewMap[ChargeType.vatavAmount] = PreviewTableRowModel(
    //   title: "vatav",
    //   charge: "$vatavAmount %",
    //   totalCharge: costing.vatavPercentage.toString(),
    // );
    final vatavPercentage = costing.vatavPercentage ?? 0;
    final vatavAmount = (costing.totalExpense * vatavPercentage) / 100;

    previewMap[ChargeType.vatavAmount] = PreviewTableRowModel(
      title: "Vatav (${vatavPercentage.toStringAsFixed(2)}%)",
      charge: vatavAmount.toStringAsFixed(2),
      totalCharge: vatavAmount.toStringAsFixed(2),
    );


    double totalPlusVatav = costing.totalExpense + vatavAmount;
    previewMap[ChargeType.totalChargesPlusVatavAmount] = PreviewTableRowModel(
      title: "total + vatav",
      charge: totalPlusVatav.toString(),
      totalCharge: totalPlusVatav.toString(),
    );

    // double profitAmount = (grandTotal * (costing.profitPercentage ?? 0)) / 100;
    // previewMap[ChargeType.profitAmount] = PreviewTableRowModel(
    //   title: "profit",
    //   charge: "$profitAmount %",
    //   totalCharge: costing.profitPercentage.toString(),
    // );

    final profitPercentage = costing.profitPercentage ?? 0;
    final profitAmount = (totalPlusVatav * profitPercentage) / 100;

    previewMap[ChargeType.profitAmount] = PreviewTableRowModel(
      title: "profit (${profitPercentage.toStringAsFixed(2)}%)",
      charge: profitAmount.toStringAsFixed(2),
      totalCharge: profitAmount.toStringAsFixed(2),
    );


    double totalPlusVatavPlusProfit =
        costing.totalExpense + vatavAmount + profitAmount;

    previewMap[ChargeType.totalChargesPlusVatavPlusProfit] =
        PreviewTableRowModel(
      title: "total + vatav + profit",
      charge: totalPlusVatavPlusProfit.toString(),
      totalCharge: totalPlusVatavPlusProfit.toString(),
    );

    return previewMap;
  }
}
