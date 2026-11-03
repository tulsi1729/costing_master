import 'package:costing_master/domain/costing_calculator.dart';

enum BargainVerdict {
  /// Below cost plus vatav: every such sale loses money.
  loss,

  /// Profitable, but at less than half the costing's own profit %.
  thin,
  good,
}

/// What selling a costing at the customer's [offer] would earn.
class Bargain {
  final double offer;

  /// Profit at [offer], after cost and vatav; negative for a loss.
  final double profit;

  /// [profit] as a % of cost plus vatav: the same base as the profit field,
  /// so setting it as the costing's profit % makes the price [offer].
  final double profitPercentage;

  /// The lowest price that still covers cost and vatav.
  final double floor;

  /// How much below the quoted price [offer] is (negative if above it).
  final double discount;
  final double discountPercentage;
  final BargainVerdict verdict;

  const Bargain._({
    required this.offer,
    required this.profit,
    required this.profitPercentage,
    required this.floor,
    required this.discount,
    required this.discountPercentage,
    required this.verdict,
  });

  factory Bargain.of(CostingBreakdown breakdown, double offer) {
    final floor = breakdown.totalWithVatav;
    final quoted = breakdown.grandTotal;
    final profit = offer - floor;
    final profitPercentage = floor == 0 ? 0.0 : profit / floor * 100;
    final verdict = profit < 0
        ? BargainVerdict.loss
        : profitPercentage < breakdown.profitPercentage / 2
            ? BargainVerdict.thin
            : BargainVerdict.good;
    return Bargain._(
      offer: offer,
      profit: profit,
      profitPercentage: profitPercentage,
      floor: floor,
      discount: quoted - offer,
      discountPercentage: quoted == 0 ? 0 : (quoted - offer) / quoted * 100,
      verdict: verdict,
    );
  }

  /// Typical counter-offers for a quoted price: rounded down to ₹10 and
  /// ₹50, and 5% and 10% off. Distinct, positive and below [quoted].
  static List<double> suggestions(double quoted) {
    double roundDown(double value, int step) =>
        (value / step).floorToDouble() * step;
    final offers = <double>{
      roundDown(quoted, 10),
      roundDown(quoted, 50),
      roundDown(quoted * 0.95, 10),
      roundDown(quoted * 0.9, 10),
    }..removeWhere((offer) => offer <= 0 || offer >= quoted);
    return offers.toList()..sort((a, b) => b.compareTo(a));
  }
}
