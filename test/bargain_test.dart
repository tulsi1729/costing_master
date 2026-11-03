import 'package:costing_master/domain/bargain.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/model/costing.dart';
import 'package:flutter_test/flutter_test.dart';

/// ₹400 cost, 5% vatav (₹420 floor), 20% profit (₹504 quoted).
Costing _costing({double profit = 20}) => Costing.fromMap({
      'guid': 'g',
      'createdBy': '',
      'clientGuid': 'c',
      'sheetBharvana': 400,
      'vatavPercentage': 5,
      'profitPercentage': profit,
    });

void main() {
  final breakdown = CostingCalculator.compute(_costing());

  test('profit, floor and discount at the customer price', () {
    final bargain = Bargain.of(breakdown, 462);
    expect(bargain.floor, closeTo(420, 1e-9));
    expect(bargain.profit, closeTo(42, 1e-9));
    expect(bargain.profitPercentage, closeTo(10, 1e-9));
    expect(bargain.discount, closeTo(42, 1e-9));
    expect(bargain.verdict, BargainVerdict.good);
  });

  test('verdicts follow the floor and half the planned profit', () {
    expect(Bargain.of(breakdown, 419).verdict, BargainVerdict.loss);
    expect(Bargain.of(breakdown, 441).verdict, BargainVerdict.thin);
    expect(Bargain.of(breakdown, 462).verdict, BargainVerdict.good);
  });

  test('applying the profit % prices the costing at the offer', () {
    final bargain = Bargain.of(breakdown, 450);
    final agreed = CostingCalculator.compute(
        _costing(profit: bargain.profitPercentage));
    expect(agreed.grandTotal, closeTo(450, 1e-6));
  });

  test('a costing without costs does not divide by zero', () {
    final empty = CostingCalculator.compute(Costing.fromMap(
        {'guid': 'g', 'createdBy': '', 'clientGuid': 'c'}));
    expect(Bargain.of(empty, 100).profitPercentage, 0);
  });

  test('suggests distinct round counter-offers below the price', () {
    expect(Bargain.suggestions(504), [500, 470, 450]);
    expect(Bargain.suggestions(0), isEmpty);
  });
}
