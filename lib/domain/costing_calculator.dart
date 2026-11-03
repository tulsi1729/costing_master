import 'package:costing_master/common/enums.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/model/sagadi_costing.dart';

/// Diamond rates are entered per 100 diamonds but stored per single diamond.
const double diamondRateUnit = 100;

enum FixedCharge {
  sheet,
  lessFitting,
  reniyaCutting,
  fusing,
  dieCutting,
  other
}

enum CostSection { patti, buta, sagadi, labour }

/// Display order of diamond rows inside each part.
const diamondOrder = [
  DiamondType.shadow,
  DiamondType.color,
  DiamondType.jarkan,
  DiamondType.dmc,
];

const sagadiOrder = [
  SagadiItemType.buta,
  SagadiItemType.less,
  SagadiItemType.valiya,
];

/// One priced line of a costing.
class BreakdownLine {
  final CostSection section;

  /// Only set for diamond lines.
  final PartType? part;
  final DiamondType? diamond;

  /// Only set for sagadi lines.
  final SagadiItemType? sagadi;

  /// Only set for fixed labour lines.
  final FixedCharge? fixed;

  /// Total pieces (diamonds or sagadi items), null for lump-sum charges.
  final double? quantity;

  /// Diamonds: rate per 100. Sagadi: rate per item. Null for lump sums.
  final double? rate;

  final double amount;

  const BreakdownLine({
    required this.section,
    required this.amount,
    this.part,
    this.diamond,
    this.sagadi,
    this.fixed,
    this.quantity,
    this.rate,
  });
}

class CostingBreakdown {
  final List<BreakdownLine> lines;
  final double totalExpense;
  final double vatavPercentage;
  final double vatavAmount;
  final double profitPercentage;
  final double profitAmount;

  const CostingBreakdown({
    required this.lines,
    required this.totalExpense,
    required this.vatavPercentage,
    required this.vatavAmount,
    required this.profitPercentage,
    required this.profitAmount,
  });

  double get totalWithVatav => totalExpense + vatavAmount;
  double get grandTotal => totalExpense + vatavAmount + profitAmount;

  double sectionTotal(CostSection section) => lines
      .where((line) => line.section == section)
      .fold(0, (sum, line) => sum + line.amount);

  /// Lines worth printing on a quote.
  Iterable<BreakdownLine> get pricedLines =>
      lines.where((line) => line.amount != 0);

  /// Lines for a quote sent to a customer: vatav and profit are spread over
  /// every line in proportion, so the lines add up to [grandTotal] and the
  /// margins are never visible.
  List<BreakdownLine> get customerLines {
    final factor = totalExpense == 0 ? 1.0 : grandTotal / totalExpense;
    return [
      for (final line in pricedLines)
        BreakdownLine(
          section: line.section,
          part: line.part,
          diamond: line.diamond,
          sagadi: line.sagadi,
          fixed: line.fixed,
          quantity: line.quantity,
          rate: line.rate == null ? null : line.rate! * factor,
          amount: line.amount * factor,
        ),
    ];
  }
}

/// The single source of truth for all costing arithmetic.
///
/// Used by the calculator screen (live totals), the quote card and when saving,
/// so the three can never disagree.
abstract final class CostingCalculator {
  static double diamondAmount(DiamondCosting? d) => d == null
      ? 0
      : d.diamondsPerPart * d.numbersOfPartsPerSari * d.diamondRate;

  static double sagadiAmount(SagadiCosting? s) =>
      s == null ? 0 : s.itemsCount * s.chargePerItem;

  static double fixedAmount(Costing costing, FixedCharge charge) =>
      switch (charge) {
        FixedCharge.sheet => costing.sheetBharvana,
        FixedCharge.lessFitting => costing.lessFiting,
        FixedCharge.reniyaCutting => costing.reniyaCutting,
        FixedCharge.fusing => costing.fusing,
        FixedCharge.dieCutting => costing.dieKapvana,
        FixedCharge.other => costing.otherCost,
      };

  static double vatavAmount(double totalExpense, double vatavPercentage) =>
      totalExpense * vatavPercentage / 100;

  /// Profit is charged on top of expense + vatav.
  static double profitAmount(
    double totalExpense,
    double vatavAmount,
    double profitPercentage,
  ) =>
      (totalExpense + vatavAmount) * profitPercentage / 100;

  static CostingBreakdown compute(Costing costing) {
    final lines = <BreakdownLine>[];

    for (final part in const [PartType.patti, PartType.buta]) {
      for (final type in diamondOrder) {
        final d = costing.diamondCostingsMap?[part]?[type];
        if (d == null) continue;
        lines.add(BreakdownLine(
          section:
              part == PartType.patti ? CostSection.patti : CostSection.buta,
          part: part,
          diamond: type,
          quantity: d.diamondsPerPart * d.numbersOfPartsPerSari,
          rate: d.diamondRate * diamondRateUnit,
          amount: diamondAmount(d),
        ));
      }
    }

    for (final type in sagadiOrder) {
      final s = costing.sagadiCostingsMap?[type];
      if (s == null) continue;
      lines.add(BreakdownLine(
        section: CostSection.sagadi,
        sagadi: type,
        quantity: s.itemsCount,
        rate: s.chargePerItem,
        amount: sagadiAmount(s),
      ));
    }

    for (final charge in FixedCharge.values) {
      lines.add(BreakdownLine(
        section: CostSection.labour,
        fixed: charge,
        amount: fixedAmount(costing, charge),
      ));
    }

    final totalExpense = lines.fold<double>(0, (sum, l) => sum + l.amount);
    final vatavPercentage = costing.vatavPercentage ?? 0;
    final profitPercentage = costing.profitPercentage ?? 0;
    final vatav = vatavAmount(totalExpense, vatavPercentage);

    return CostingBreakdown(
      lines: List.unmodifiable(lines),
      totalExpense: totalExpense,
      vatavPercentage: vatavPercentage,
      vatavAmount: vatav,
      profitPercentage: profitPercentage,
      profitAmount: profitAmount(totalExpense, vatav, profitPercentage),
    );
  }

  /// Returns [costing] with its stored totals recomputed from its inputs.
  static Costing withTotals(Costing costing) {
    final breakdown = compute(costing);
    return costing.copyWith(
      totalExpense: breakdown.totalExpense,
      totalChargesPlusVatavAmount: breakdown.totalWithVatav,
      totalChargesPlusVatavPlusProfit: breakdown.grandTotal,
    );
  }
}
