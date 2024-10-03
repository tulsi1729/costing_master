import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/login.dart';
import 'package:costing_master/common/enums.dart';
import 'package:costing_master/constants.dart';
import 'package:costing_master/costing/notifier/costing_notifier.dart';
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
import 'package:costing_master/widgets/my_text_field.dart';
import 'package:costing_master/widgets/sagadi_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String clientName;
  final String costingGUID;
  final String clientUid;
  InfoModel info;
  HomeScreen({
    super.key,
    required this.clientName,
    required this.costingGUID,
    required this.info,
    required this.clientUid,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Map<ChargeType, double> chargesMap = {
    ChargeType.patiShadowDiamond: 0,
    ChargeType.patiColorDiamond: 0,
    ChargeType.patiJarkan: 0,
    ChargeType.patiDMC: 0,
    ChargeType.butaShadowDiamond: 0,
    ChargeType.butaColorDiamond: 0,
    ChargeType.butaJarkan: 0,
    ChargeType.butaDMC: 0,
    ChargeType.sheetCharges: 0,
    ChargeType.butaSagadiCharges: 0,
    ChargeType.lessSagadiCharges: 0,
    ChargeType.valiyaSagadiCharges: 0,
    ChargeType.lessFiting: 0,
    ChargeType.reniyaCutting: 0,
    ChargeType.fusing: 0,
    ChargeType.dieKapvana: 0,
    ChargeType.otherCharges: 0,
  };

  Map<ChargeType, DiamondCosting> diamondCostingsMap = {};
  Map<ChargeType, SagadiCosting> sagadiCostingsMap = {};

  double totalExpense = 0;
  double vatavAmount = 0;
  double profitAmount = 0;
  double profitPercentage = 0;
  double vatavPercentage = 0;

  final GlobalKey<_SingleInputRowState> _vatavWidgetKey =
      GlobalKey<_SingleInputRowState>();
  final GlobalKey<_SingleInputRowState> _profitWidgetKey =
      GlobalKey<_SingleInputRowState>();

  void logOut() {
    ref.read(authProvider.notifier).logOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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
                ..._buildDiamondInputRows(_singleInputDiamondList),
                ..._buildSagadiInputRows(_sagadiInputData),
                const MyDivider(),
                ..._buildSingleInputRows(_singleInputChargesList),
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
                    });
                    return vatavAmount;
                  },
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
                      MyAnswer(answer: totalExpense + vatavAmount),
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
                      profitAmount =
                          (totalExpense + vatavAmount) * profitPercentage / 100;
                      this.profitPercentage = profitPercentage;
                    });
                    return profitAmount;
                  },
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
                        answer: totalExpense + vatavAmount + profitAmount,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                    onPressed: () async {
                      UserModel userModel =
                          (await ref.read(authProvider.future))!;

                      final Costing costing = Costing(
                        guid: widget.costingGUID,
                        createdBy: userModel.uid,
                        clientUid: widget.clientUid,
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
                        diamondCostings: diamondCostingsMap.values.toList(),
                        sagadiCostings: sagadiCostingsMap.values.toList(),
                      );

                      await ref
                          .read(costingProvider.notifier)
                          .createCosting(costing);
                      // await ref
                      //     .read(costingProvider.notifier)
                      //     .refresh()
                      //     .then((value) => Navigator.pop(context));
                    },
                    child: const Text("SAVE")),
                const SizedBox(
                  height: 50,
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
    diamondCostingsMap[chargesType] = diamondCosting;
  }

  void onChangesSagadiRow(
    ChargeType chargesType,
    double charges,
    SagadiCosting sagadiCosting,
  ) {
    onChanges(chargesType, charges);
    sagadiCostingsMap[chargesType] = sagadiCosting;
  }

  List<Widget> _buildSingleInputRows(List<Map<String, dynamic>> data) {
    List<Widget> rows = [];
    for (int i = 0; i < data.length; i++) {
      rows.add(
        SingleInputRow(
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
            partType: data[i]['partType'],
            diamondType: data[i]['diamondType'],
            onChanged: (charges, diamongCosting) {
              onChangesDiamondRow(
                data[i]['chargeType'],
                charges,
                diamongCosting,
              );
            }),
      );
      if (i < data.length - 1) {
        rows.add(const MyDivider());
      }
    }
    return rows;
  }

  final _singleInputDiamondList = [
    {
      "partType": PartType.buta,
      "diamondType": DiamondType.shadow,
      "chargeType": ChargeType.patiShadowDiamond,
    },
    {
      "partType": PartType.buta,
      "diamondType": DiamondType.color,
      "chargeType": ChargeType.patiColorDiamond,
    },
    {
      "partType": PartType.buta,
      "diamondType": DiamondType.jarkan,
      "chargeType": ChargeType.patiJarkan,
    },
    {
      "partType": PartType.buta,
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

  final _singleInputChargesList = [
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

  final _sagadiInputData = [
    {
      "labelText": "સગડી બુટા",
      "chargeType": ChargeType.butaSagadiCharges,
    },
    {
      "labelText": "સગડી લેસ",
      "chargeType": ChargeType.lessSagadiCharges,
    },
    {
      "labelText": "સગડી વળીયા",
      "chargeType": ChargeType.valiyaSagadiCharges,
    },
  ];
}

class SingleInputRow extends StatefulWidget {
  final String labelText;
  final String suffixText;
  final TextEditingController? controller;
  final double? Function(double) onChanged;

  const SingleInputRow({
    super.key,
    required this.labelText,
    required this.onChanged,
    this.controller,
    this.suffixText = inrSymbol,
  });

  @override
  State<SingleInputRow> createState() => _SingleInputRowState();
}

class _SingleInputRowState extends State<SingleInputRow> {
  double charges = 0;
  String selectedValue = "";
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MyTextField(
          labelText: widget.labelText,
          suffixText: widget.suffixText,
          controller: widget.controller,
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
      this.charges = widget.onChanged(charges) ?? charges;
    });
  }
}
