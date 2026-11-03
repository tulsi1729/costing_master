import 'package:costing_master/common/enums.dart';
import 'package:costing_master/domain/costing_calculator.dart';

/// A Gujarati label with a short English hint shown underneath.
class Label {
  final String gu;
  final String en;
  const Label(this.gu, this.en);
}

abstract final class Labels {
  static const partNames = {
    PartType.patti: Label('પટ્ટી', 'Patti'),
    PartType.buta: Label('બુટા', 'Buta'),
  };

  static const diamondNames = {
    DiamondType.shadow: Label('શેડો ડાયમંડ', 'Shadow'),
    DiamondType.color: Label('કલર ડાયમંડ', 'Color'),
    DiamondType.jarkan: Label('જરકન', 'Jarkan'),
    DiamondType.dmc: Label('DMC ડાયમંડ', 'DMC'),
  };

  static const sagadiNames = {
    SagadiItemType.buta: Label('સગડી બુટા', 'Sagadi buta'),
    SagadiItemType.less: Label('સગડી લેસ', 'Sagadi lace'),
    SagadiItemType.valiya: Label('સગડી વળીયા', 'Sagadi valiya'),
  };

  static const fixedCharges = {
    FixedCharge.sheet: Label('સીટ ભરવાના (જરકન + DMC)', 'Sheet filling'),
    FixedCharge.lessFitting: Label('લેસ ફીટીંગ', 'Lace fitting'),
    FixedCharge.reniyaCutting: Label('રેણીયા કટીંગ', 'Reniya cutting'),
    FixedCharge.fusing: Label('ફ્યુઝિંગ', 'Fusing'),
    FixedCharge.dieCutting: Label('ડાય કાપવાના', 'Die cutting'),
    FixedCharge.other: Label('અન્ય ખર્ચ', 'Other'),
  };

  static const sections = {
    CostSection.patti: Label('પટ્ટી ડાયમંડ', 'Patti diamonds'),
    CostSection.buta: Label('બુટા ડાયમંડ', 'Buta diamonds'),
    CostSection.sagadi: Label('સગડી', 'Sagadi labour'),
    CostSection.labour: Label('મજૂરી', 'Labour & other'),
  };

  static const totalExpense = Label('કુલ ખર્ચ', 'Total expense');
  static const vatav = Label('વટાવ', 'Vatav');
  static const profit = Label('નફો', 'Profit');
  static const totalWithVatav = Label('ખર્ચ + વટાવ', 'Expense + vatav');
  static const finalPrice = Label('અંતિમ ભાવ', 'Final price');
  static const margins = Label('વટાવ અને નફો', 'Vatav & profit');

  static String diamondLine(PartType part, DiamondType type) =>
      '${partNames[part]!.gu} ${diamondNames[type]!.gu}';

  static String diamondLineEn(PartType part, DiamondType type) =>
      '${partNames[part]!.en} ${diamondNames[type]!.en}';
}
