import 'package:costing_master/common/enums.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/money.dart';
import 'package:costing_master/model/costing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape of a costing document as stored in Firestore by v1 of the app.
Map<String, dynamic> storedCosting({bool intsInsteadOfDoubles = false}) {
  num n(double v) =>
      intsInsteadOfDoubles && v == v.roundToDouble() ? v.toInt() : v;
  return {
    'guid': 'g1',
    'createdBy': 'u1',
    'designNo': 501,
    'clientGuid': 'c1',
    'sariName': 'Rani',
    'imageUrl': 'https://example.com/a.png',
    'sheetBharvana': n(50.0),
    'lessFiting': n(20.0),
    'reniyaCutting': n(0.0),
    'fusing': n(10.0),
    'dieKapvana': n(0.0),
    'otherCost': n(5.0),
    'vatavPercentage': n(2.0),
    'profitPercentage': n(10.0),
    'totalExpense': n(235.0),
    'totalChargesPlusVatavAmount': 239.7,
    'totalChargesPlusVatavPlusProfit': 263.67,
    'diamondCostingsMap': {
      'patti': {
        'shadow': {
          'diamondType': 'shadow',
          'diamondRate': 0.5, // ₹50 per 100 diamonds
          'diamondsPerPart': 20,
          'numbersOfPartsPerSari': n(10.0),
          'partType': 'patti',
        },
      },
      'buta': {
        'dmc': {
          'diamondType': 'dmc',
          'diamondRate': 0.25,
          'diamondsPerPart': 4,
          'numbersOfPartsPerSari': n(20.0),
          'partType': 'buta',
        },
      },
    },
    'sagadiCostingsMap': {
      'SagadiItemType.buta': {
        'itemType': 'buta',
        'itemsCount': n(10.0),
        'chargePerItem': n(3.0),
      },
    },
  };
}

void main() {
  group('CostingCalculator', () {
    final costing = Costing.fromMap(storedCosting());
    final breakdown = CostingCalculator.compute(costing);

    test('diamond line multiplies per-part × parts × rate', () {
      final patti = breakdown.lines.firstWhere(
          (l) => l.part == PartType.patti && l.diamond == DiamondType.shadow);
      expect(patti.quantity, 200);
      expect(patti.rate, 50);
      expect(patti.amount, 100);
    });

    test('lines add up to the total expense', () {
      final sum = breakdown.lines.fold<double>(0, (s, l) => s + l.amount);
      expect(sum, breakdown.totalExpense);
      // 100 (patti) + 20 (buta) + 30 (sagadi) + 85 (labour)
      expect(breakdown.totalExpense, 235);
      expect(breakdown.sectionTotal(CostSection.patti), 100);
      expect(breakdown.sectionTotal(CostSection.buta), 20);
      expect(breakdown.sectionTotal(CostSection.sagadi), 30);
      expect(breakdown.sectionTotal(CostSection.labour), 85);
    });

    test('profit is charged on expense + vatav', () {
      expect(breakdown.vatavAmount, closeTo(4.7, 1e-9));
      expect(breakdown.totalWithVatav, closeTo(239.7, 1e-9));
      expect(breakdown.profitAmount, closeTo(23.97, 1e-9));
      expect(breakdown.grandTotal, closeTo(263.67, 1e-9));
    });

    test('reproduces the totals stored by v1 of the app', () {
      final stored = storedCosting();
      expect(breakdown.totalExpense, stored['totalExpense']);
      expect(breakdown.grandTotal,
          closeTo(stored['totalChargesPlusVatavPlusProfit'] as double, 1e-9));
    });

    test('withTotals writes recomputed totals', () {
      final drifted = costing.copyWith(totalExpense: 1);
      final fixed = CostingCalculator.withTotals(drifted);
      expect(fixed.totalExpense, 235);
      expect(fixed.totalChargesPlusVatavPlusProfit, closeTo(263.67, 1e-9));
    });

    test('customer lines hide margins but add up to the final price', () {
      final customer = breakdown.customerLines;
      final sum = customer.fold<double>(0, (s, l) => s + l.amount);
      expect(sum, closeTo(breakdown.grandTotal, 1e-9));
      expect(customer.length, breakdown.pricedLines.length);
      final patti = customer.first;
      expect(patti.amount, greaterThan(100));
      expect(patti.rate! * patti.quantity! / diamondRateUnit,
          closeTo(patti.amount, 1e-9));
    });

    test('empty costing is all zeros', () {
      final empty = CostingCalculator.compute(costing.copyWith(
        diamondCostingsMap: {},
        sagadiCostingsMap: {},
        sheetBharvana: 0,
        lessFiting: 0,
        fusing: 0,
        otherCost: 0,
      ));
      expect(empty.grandTotal, 0);
      expect(empty.pricedLines, isEmpty);
    });
  });

  group('Costing.fromMap', () {
    test('accepts ints where doubles are expected', () {
      final costing =
          Costing.fromMap(storedCosting(intsInsteadOfDoubles: true));
      expect(costing.sheetBharvana, 50.0);
      expect(
          costing.diamondCostingsMap![PartType.patti]![DiamondType.shadow]!
              .numbersOfPartsPerSari,
          10.0);
      expect(costing.sagadiCostingsMap![SagadiItemType.buta]!.itemsCount, 10.0);
    });

    test('round-trips through toMap', () {
      final costing = Costing.fromMap(storedCosting());
      final again = Costing.fromMap(costing.toMap());
      expect(CostingCalculator.compute(again).grandTotal,
          CostingCalculator.compute(costing).grandTotal);
      expect(again.designNo, 501);
    });
  });

  group('money', () {
    test('Indian grouping', () {
      expect(formatIndian(0), '0.00');
      expect(formatIndian(999), '999.00');
      expect(formatIndian(1000), '1,000.00');
      expect(formatIndian(123456.5), '1,23,456.50');
      expect(formatIndian(12345678), '1,23,45,678.00');
      expect(formatIndian(-1500), '-1,500.00');
      expect(formatRupees(2500, decimals: 0), '₹2,500');
    });

    test('Gujarati digits', () {
      expect(formatIndian(1234.5, gujaratiDigits: true), '૧,૨૩૪.૫૦');
      expect(parseAmount('૧૨'), 12);
    });

    test('input formatting and parsing', () {
      expect(formatInput(12.0), '12');
      expect(formatInput(0.5), '0.5');
      expect(formatInput(0), '');
      expect(parseAmount('1,200'), 1200);
      expect(parseAmount(''), 0);
      expect(parseAmount('abc'), 0);
    });
  });
}
