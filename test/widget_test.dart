import 'package:costing_master/common/enums.dart';
import 'package:costing_master/costings/calculator/costing_calculator_screen.dart';
import 'package:costing_master/costings/quote/quote_card.dart';
import 'package:costing_master/domain/labels.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home) => ProviderScope(
      child: MaterialApp(theme: AppTheme.light(AppColor.navy), home: home),
    );

Costing _costing() => Costing(
      guid: 'g',
      createdBy: 'u',
      clientGuid: 'c',
      designNo: 7,
      sariName: 'Rani',
      imageUrl: '',
      sheetBharvana: 100,
      lessFiting: 0,
      reniyaCutting: 0,
      fusing: 0,
      dieKapvana: 0,
      otherCost: 0,
      vatavPercentage: 10,
      profitPercentage: 10,
      totalExpense: 0,
      totalChargesPlusVatavAmount: 0,
      totalChargesPlusVatavPlusProfit: 0,
      diamondCostingsMap: {
        PartType.patti: {
          DiamondType.shadow: DiamondCosting(
            diamondType: DiamondType.shadow,
            partType: PartType.patti,
            diamondRate: 0.5,
            diamondsPerPart: 10,
            numbersOfPartsPerSari: 20,
          ),
        },
      },
      sagadiCostingsMap: {},
    );

void main() {
  testWidgets('calculator updates the final price live', (tester) async {
    await tester.pumpWidget(_app(const CostingCalculatorScreen(
      clientGuid: 'c',
      clientName: 'Client',
      userUid: 'u',
    )));
    await tester.pumpAndSettle();
    expect(find.text('₹0.00'), findsWidgets);

    final sheetField =
        find.widgetWithText(TextField, Labels.fixedCharges.values.first.gu);
    await tester.scrollUntilVisible(
      sheetField,
      200,
      scrollable: find
          .descendant(
              of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await tester.enterText(sheetField, '250');
    await tester.pumpAndSettle();

    // Total bar, labour subtotal and breakdown all reflect the new charge.
    expect(find.text('₹250.00'), findsWidgets);
  });

  testWidgets('editing a saved costing shows the per-100 rate', (tester) async {
    await tester.pumpWidget(_app(CostingCalculatorScreen(
      clientGuid: 'c',
      clientName: 'Client',
      userUid: 'u',
      costing: _costing(),
    )));
    await tester.pumpAndSettle();

    // Stored per-diamond rate 0.5 is shown as ₹50 per 100 diamonds.
    final rateField = find.widgetWithText(TextField, '100 નો ભાવ').first;
    expect(tester.widget<TextField>(rateField).controller!.text, '50');
    // (10 × 20 × 0.5 = 100) + 100 sheet = 200; +10% vatav = 220; +10% = 242.
    expect(find.text('₹242.00'), findsOneWidget);
  });

  testWidgets('customer quote hides margins, internal shows them',
      (tester) async {
    Future<void> pump(QuoteMode mode) => tester.pumpWidget(MaterialApp(
          home: SingleChildScrollView(
            child: QuoteCard(
              costing: _costing(),
              clientName: 'Client',
              profile: const BusinessProfile(businessName: 'Shree Crafts'),
              style: const QuoteStyle(),
              mode: mode,
              date: DateTime(2026, 1, 2),
            ),
          ),
        ));

    await pump(QuoteMode.customer);
    expect(find.text('Shree Crafts'), findsOneWidget);
    expect(find.text('₹242.00'), findsOneWidget);
    expect(find.textContaining(Labels.vatav.gu), findsNothing);

    await pump(QuoteMode.internal);
    expect(find.textContaining(Labels.vatav.gu), findsWidgets);
    expect(find.text('₹242.00'), findsOneWidget);
  });
}
