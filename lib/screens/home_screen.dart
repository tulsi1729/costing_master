import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/login.dart';
import 'package:costing_master/constants.dart';
import 'package:costing_master/domain/enums.dart';
import 'package:costing_master/auth/screens/sign_in_button.dart';
import 'package:costing_master/widgets/border_container.dart';
import 'package:costing_master/widgets/diamonds_rate_row.dart';
import 'package:costing_master/widgets/my_answer.dart';
import 'package:costing_master/widgets/my_divider.dart';
import 'package:costing_master/widgets/my_text_field.dart';
import 'package:costing_master/widgets/sagadi_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Map<ChargeType, double> chargesMap = {
    ChargeType.buta: 0,
    ChargeType.pati: 0,
    ChargeType.sheetCharges: 0,
    ChargeType.butaSagadiCharges: 0,
    ChargeType.lessSagadiCharges: 0,
    ChargeType.valiyaSagadiCharges: 0,
    ChargeType.lessFiting: 0,
    ChargeType.reniyaCutting: 0,
    ChargeType.fusing: 0,
    ChargeType.dieCharges: 0,
    ChargeType.otherCharges: 0,
  };
  double totalExpense = 0;
  double vatavAmount = 0;
  double profitAmount = 0;
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
    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(
        child: Column(
          children: [
            TextButton(onPressed: () => logOut(), child: const Text("Log Out")),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(top: 28),
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  DiamondsRateRow(
                    elementName: "પટ્ટી",
                    onChanged: (charges) => onChanges(
                      ChargeType.pati,
                      charges,
                    ),
                  ),
                  const MyDivider(),
                  DiamondsRateRow(
                    elementName: "બુટા",
                    onChanged: (charges) => onChanges(
                      ChargeType.buta,
                      charges,
                    ),
                  ),
                  const MyDivider(),
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
                        MyAnswer(answer: totalExpense),
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
                        profitAmount = (totalExpense + vatavAmount) *
                            profitPercentage /
                            100;
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
                            answer: totalExpense + vatavAmount + profitAmount),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  )
                ],
              ),
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
          onChanged: (charges) => onChanges(
            data[i]['chargeType'],
            charges,
          ),
        ),
      );
      if (i < data.length - 1) {
        rows.add(const MyDivider());
      }
    }
    return rows;
  }

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
      "chargeType": ChargeType.dieCharges,
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
        MyAnswer(answer: charges),
        const SizedBox(
          height: 24,
        )
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
