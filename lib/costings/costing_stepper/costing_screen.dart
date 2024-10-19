import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/login.dart';
import 'package:costing_master/common/enums.dart';
import 'package:costing_master/domain/enums.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/model/info_model.dart';
import 'package:costing_master/model/sagadi_costing.dart';
import 'package:costing_master/model/user_model.dart';
import 'package:costing_master/widgets/border_container.dart';
import 'package:costing_master/widgets/diamonds_rate_row.dart';
import 'package:costing_master/widgets/my_answer.dart';
import 'package:costing_master/widgets/my_divider.dart';
import 'package:costing_master/widgets/sagadi_input_field.dart';
import 'package:costing_master/widgets/single_input_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CostingScreen extends ConsumerStatefulWidget {
  final String clientName;
  final String costingGUID;
  final String clientGuid;
  final InfoModel info;
  final Costing? costing;

  final void Function(Costing) costingUpdate;

  const CostingScreen({
    super.key,
    required this.clientName,
    required this.costingGUID,
    required this.info,
    required this.clientGuid,
    required this.costingUpdate,
    required this.costing,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => CostingScreenState();
}

class CostingScreenState extends ConsumerState<CostingScreen> {
  late final Map<ChargeType, double> chargesMap;
  Map<PartType, Map<DiamondType, DiamondCosting>> diamondCostingsMap = {};
  Map<SagadiItemType, SagadiCosting> sagadiCostingsMap = {};

  double totalExpense = 0;
  double vatavAmount = 0;
  double profitAmount = 0;
  double? profitPercentage;
  double? vatavPercentage;

  final GlobalKey<SingleInputRowState> _vatavWidgetKey =
      GlobalKey<SingleInputRowState>();
  final GlobalKey<SingleInputRowState> _profitWidgetKey =
      GlobalKey<SingleInputRowState>();

  void logOut() {
    ref.read(authProvider.notifier).logOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future saveCostingModelToParent() async {
    UserModel userModel = (await ref.read(authProvider.future))!;

    final double totalChargesPlusVatavAmount = totalExpense + vatavAmount;
    final double totalChargesPlusVatavAmountPlusProfit =
        totalExpense + vatavAmount + profitAmount;
    widget.costingUpdate(
      Costing(
        guid: widget.costingGUID,
        createdBy: userModel.uid,
        clientGuid: widget.clientGuid,
        designNo: widget.info.designNo,
        sariName: widget.info.sariName,
        imageUrl: widget.info.imageUrl,
        sheetBharvana: chargesMap[ChargeType.sheetCharges]!,
        lessFiting: chargesMap[ChargeType.lessFiting]!,
        reniyaCutting: chargesMap[ChargeType.reniyaCutting]!,
        fusing: chargesMap[ChargeType.fusing]!,
        dieKapvana: chargesMap[ChargeType.dieKapvana]!,
        otherCost: chargesMap[ChargeType.otherCharges]!,
        vatavPercentage: vatavPercentage,
        profitPercentage: profitPercentage,
        totalExpense: totalExpense,
        totalChargesPlusVatavAmount: totalChargesPlusVatavAmount,
        totalChargesPlusVatavPlusProfit: totalChargesPlusVatavAmountPlusProfit,
        diamondCostingsMap: diamondCostingsMap,
        sagadiCostingsMap: sagadiCostingsMap,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    chargesMap = {
      ChargeType.patiShadowDiamond: 0,
      ChargeType.patiColorDiamond: 0,
      ChargeType.patiJarkan: 0,
      ChargeType.patiDMC: 0,
      ChargeType.butaShadowDiamond: 0,
      ChargeType.butaColorDiamond: 0,
      ChargeType.butaJarkan: 0,
      ChargeType.butaDMC: 0,
      ChargeType.butaSagadiCharges: 0,
      ChargeType.lessSagadiCharges: 0,
      ChargeType.valiyaSagadiCharges: 0,
      ChargeType.sheetCharges: widget.costing?.sheetBharvana ?? 0,
      ChargeType.lessFiting: widget.costing?.lessFiting ?? 0,
      ChargeType.reniyaCutting: widget.costing?.reniyaCutting ?? 0,
      ChargeType.fusing: widget.costing?.fusing ?? 0,
      ChargeType.dieKapvana: widget.costing?.dieKapvana ?? 0,
      ChargeType.otherCharges: widget.costing?.otherCost ?? 0,
    };
    vatavPercentage = widget.costing?.vatavPercentage;
    profitPercentage = widget.costing?.profitPercentage;
    totalExpense = widget.costing?.totalExpense ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 28),
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                ..._buildDiamondInputRows(singleInputDiamondList),
                const MyDivider(),
                ..._buildSagadiInputRows(sagadiInputData),
                const MyDivider(),
                ..._buildSingleInputRows(
                    CostingScreenState.singleInputChargesList),
                const MyDivider(),
                BorderContainer(
                  color: Colors.orange,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('ટોટલ ખર્ચ'),
                        ),
                      ),
                      const Text(" = "),
                      MyAnswer(
                        answer: totalExpense,
                      ),
                    ],
                  ),
                ),
                const MyDivider(),
                SingleInputRow(
                  labelText: 'વટાવ',
                  suffixText: '%',
                  key: _vatavWidgetKey,
                  onChanged: (vatavPercentage) {
                    setState(() {
                      vatavAmount = totalExpense * vatavPercentage / 100;
                      this.vatavPercentage = vatavPercentage;
                    });
                    return vatavPercentage;
                  },
                  initialValue: vatavPercentage == 0 ? null : vatavPercentage,
                ),
                const MyDivider(),
                BorderContainer(
                  color: Colors.orange,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('ટોટલ ખર્ચ + વટાવ'),
                        ),
                      ),
                      const Text(" = "),
                      MyAnswer(answer: totalExpense + (vatavPercentage ?? 0)),
                    ],
                  ),
                ),
                const MyDivider(),
                SingleInputRow(
                  labelText: 'નફો',
                  key: _profitWidgetKey,
                  suffixText: '%',
                  onChanged: (profitPercentage) {
                    setState(() {
                      profitAmount = totalExpense * profitPercentage / 100;
                      this.profitPercentage = profitPercentage;
                    });
                    return profitPercentage;
                  },
                  initialValue: profitPercentage == 0 ? null : profitPercentage,
                ),
                const MyDivider(),
                BorderContainer(
                  color: Colors.green,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('ટોટલ ખર્ચ + વટાવ + નફો'),
                        ),
                      ),
                      const Text(" = "),
                      MyAnswer(
                          answer: totalExpense +
                              (vatavPercentage ?? 0) +
                              (profitPercentage ?? 0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void onChanges(ChargeType chargesType, double charges) {
    totalExpense -= chargesMap[chargesType]!;
    setState(() {
      totalExpense += charges;
    });
    _vatavWidgetKey.currentState?.updateState();
    _profitWidgetKey.currentState?.updateState();
    chargesMap[chargesType] = charges;
  }

  void onChangesDiamondRow(
    ChargeType chargesType,
    double charges,
    DiamondCosting diamondCosting,
  ) {
    onChanges(chargesType, charges);
    if (diamondCostingsMap[diamondCosting.partType] != null) {
      diamondCostingsMap[diamondCosting.partType]![diamondCosting.diamondType] =
          diamondCosting;
    } else {
      diamondCostingsMap[diamondCosting.partType] = {};
      diamondCostingsMap[diamondCosting.partType]![diamondCosting.diamondType] =
          diamondCosting;
    }
  }

  void onChangesSagadiRow(
    ChargeType chargesType,
    double charges,
    SagadiCosting sagadiCosting,
  ) {
    onChanges(chargesType, charges);
    sagadiCostingsMap[sagadiCosting.itemType] = sagadiCosting;
  }

  List<Widget> _buildSingleInputRows(List<Map<String, dynamic>> data) {
    List<Widget> rows = [];
    for (int i = 0; i < data.length; i++) {
      rows.add(
        SingleInputRow(
          initialValue: chargesMap[data[i]['chargeType']] == 0
              ? null
              : chargesMap[data[i]['chargeType']],
          labelText: data[i]['labelText'],
          onChanged: (charges) {
            onChanges(
              data[i]['chargeType'],
              charges,
            );
            return null;
          },
        ),
      );
      if (i < data.length - 1) {
        rows.add(const MyDivider());
      }
    }
    return rows;
  }

  List<Widget> _buildSagadiInputRows(List<Map<String, dynamic>> data) {
    List<Widget> rows = [];
    for (int i = 0; i < data.length; i++) {
      rows.add(
        SagadiInputField(
            sagadiCosting:
                widget.costing?.sagadiCostingsMap?[data[i]['itemType']],
            itemType: data[i]["itemType"],
            labelText: data[i]['labelText'],
            onChanged: (charges, sagadiCosting) {
              onChangesSagadiRow(
                data[i]['chargeType'],
                charges,
                sagadiCosting,
              );
            }),
      );
      if (i < data.length - 1) {
        rows.add(const MyDivider());
      }
    }
    return rows;
  }

  List<Widget> _buildDiamondInputRows(List<Map<String, dynamic>> data) {
    List<Widget> rows = [];
    for (int i = 0; i < data.length; i++) {
      rows.add(
        DiamondsRateRow(
          diamondCosting:
              widget.costing?.diamondCostingsMap?[data[i]['partType']]
                  ?[data[i]['diamondType']],
          partType: data[i]['partType'],
          diamondType: data[i]['diamondType'],
          onChanged: (charges, diamondCosting) {
            onChangesDiamondRow(
              data[i]['chargeType'],
              charges,
              diamondCosting,
            );
          },
        ),
      );
      if (i < data.length - 1) {
        rows.add(const MyDivider());
      }
    }
    return rows;
  }

  final singleInputDiamondList = [
    {
      "partType": PartType.patti,
      "diamondType": DiamondType.shadow,
      "chargeType": ChargeType.patiShadowDiamond,
    },
    {
      "partType": PartType.patti,
      "diamondType": DiamondType.color,
      "chargeType": ChargeType.patiColorDiamond,
    },
    {
      "partType": PartType.patti,
      "diamondType": DiamondType.jarkan,
      "chargeType": ChargeType.patiJarkan,
    },
    {
      "partType": PartType.patti,
      "diamondType": DiamondType.dmc,
      "chargeType": ChargeType.patiDMC,
    },
    {
      "partType": PartType.buta,
      "diamondType": DiamondType.shadow,
      "chargeType": ChargeType.butaShadowDiamond,
    },
    {
      "partType": PartType.buta,
      "diamondType": DiamondType.color,
      "chargeType": ChargeType.butaColorDiamond,
    },
    {
      "partType": PartType.buta,
      "diamondType": DiamondType.jarkan,
      "chargeType": ChargeType.butaJarkan,
    },
    {
      "partType": PartType.buta,
      "diamondType": DiamondType.dmc,
      "chargeType": ChargeType.butaDMC,
    }
  ];

  static List<Map<String, dynamic>> singleInputChargesList = [
    {
      "labelText": "સીટ ભરવાના (જરકન + DMC)",
      "chargeType": ChargeType.sheetCharges,
    },
    {
      "labelText": "લેસ ફીટીંગ",
      "chargeType": ChargeType.lessFiting,
    },
    {
      "labelText": "રેણીયા કટીંગ",
      "chargeType": ChargeType.reniyaCutting,
    },
    {
      "labelText": "ફ્યુઝિંગ",
      "chargeType": ChargeType.fusing,
    },
    {
      "labelText": "ડાય કાપવાના",
      "chargeType": ChargeType.dieKapvana,
    },
    {
      "labelText": "અન્ય ખર્ચ",
      "chargeType": ChargeType.otherCharges,
    },
  ];

  final sagadiInputData = [
    {
      "labelText": "સગડી બુટા",
      "chargeType": ChargeType.butaSagadiCharges,
      "itemType": SagadiItemType.buta,
    },
    {
      "labelText": "સગડી લેસ",
      "chargeType": ChargeType.lessSagadiCharges,
      "itemType": SagadiItemType.less,
    },
    {
      "labelText": "સગડી વળીયા",
      "chargeType": ChargeType.valiyaSagadiCharges,
      "itemType": SagadiItemType.valiya,
    },
  ];
}
