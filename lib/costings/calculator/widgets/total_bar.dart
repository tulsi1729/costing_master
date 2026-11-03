import 'package:costing_master/costings/calculator/costing_draft.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/labels.dart';
import 'package:costing_master/domain/money.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/animated_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sticky footer with the live final price and the save button.
class TotalBar extends ConsumerWidget {
  final DraftProvider draft;
  final bool saving;
  final VoidCallback onSave;

  const TotalBar({
    super.key,
    required this.draft,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdown = ref.watch(draft.select((d) => d.breakdown));
    final brand = context.brand;

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: brand.heroGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showBreakdown(context, breakdown),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${Labels.finalPrice.gu} · ${Labels.finalPrice.en}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_up_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.75)),
                          ],
                        ),
                        // Only the counting total repaints while it animates.
                        RepaintBoundary(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: AnimatedAmount(
                              breakdown.grandTotal,
                              style: TextStyle(
                                color: brand.heroAccent,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'ખર્ચ ${formatRupees(breakdown.totalExpense, decimals: 0)}'
                          '  ·  વટાવ ${formatRupees(breakdown.vatavAmount, decimals: 0)}'
                          '  ·  નફો ${formatRupees(breakdown.profitAmount, decimals: 0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: saving ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: brand.heroAccent,
                    foregroundColor: brand.onHeroAccent,
                    disabledBackgroundColor:
                        brand.heroAccent.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                  ),
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.fast),
                    child: saving
                        ? SizedBox.square(
                            key: const ValueKey('saving'),
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: brand.onHeroAccent,
                            ),
                          )
                        : const Row(
                            key: ValueKey('save'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded),
                              SizedBox(width: 6),
                              Text('સેવ કરો'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBreakdown(BuildContext context, CostingBreakdown b) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        Widget line(String label, double value, {bool strong = false}) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontWeight:
                                strong ? FontWeight.w800 : FontWeight.w500,
                            fontSize: strong ? 17 : 15)),
                  ),
                  Text(
                    formatRupees(value),
                    style: TextStyle(
                      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                      fontSize: strong ? 17 : 15,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final section in CostSection.values)
                  line(Labels.sections[section]!.gu, b.sectionTotal(section)),
                const Divider(height: 20),
                line(Labels.totalExpense.gu, b.totalExpense, strong: true),
                line('${Labels.vatav.gu} (${formatInput(b.vatavPercentage)}%)',
                    b.vatavAmount),
                line(Labels.totalWithVatav.gu, b.totalWithVatav),
                line(
                    '${Labels.profit.gu} (${formatInput(b.profitPercentage)}%)',
                    b.profitAmount),
                const Divider(height: 20),
                line(Labels.finalPrice.gu, b.grandTotal, strong: true),
              ],
            ),
          ),
        );
      },
    );
  }
}
