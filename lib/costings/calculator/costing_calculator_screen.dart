import 'dart:async';

import 'package:costing_master/common/enums.dart';
import 'package:costing_master/costings/bargain/bargain_sheet.dart';
import 'package:costing_master/costings/calculator/costing_draft.dart';
import 'package:costing_master/costings/calculator/widgets/cost_rows.dart';
import 'package:costing_master/costings/calculator/widgets/design_header.dart';
import 'package:costing_master/costings/calculator/widgets/section_card.dart';
import 'package:costing_master/costings/calculator/widgets/total_bar.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/costings/quote/quote_screen.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/labels.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One screen to enter a whole costing: photo and name on top, collapsible
/// sections below and the live final price pinned to the bottom.
class CostingCalculatorScreen extends ConsumerStatefulWidget {
  final String clientGuid;
  final String clientName;
  final String userUid;
  final Costing? costing;

  /// Opens a new costing pre-filled from this one.
  final Costing? copyOf;

  const CostingCalculatorScreen({
    super.key,
    required this.clientGuid,
    required this.clientName,
    required this.userUid,
    this.costing,
    this.copyOf,
  });

  @override
  ConsumerState<CostingCalculatorScreen> createState() =>
      _CostingCalculatorScreenState();
}

class _CostingCalculatorScreenState
    extends ConsumerState<CostingCalculatorScreen> {
  late final DraftProvider _draft = costingDraftProvider(DraftSeed(
    clientGuid: widget.clientGuid,
    clientName: widget.clientName,
    userUid: widget.userUid,
    existing: widget.costing,
    copyOf: widget.copyOf,
  ));
  final _scroll = ScrollController();
  bool _showErrors = false;
  bool _saving = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final draft = ref.read(_draft);
    if (!draft.canSave) {
      setState(() => _showErrors = true);
      unawaited(HapticFeedback.mediumImpact());
      final missing = [
        if (!draft.hasName) 'સાડીનું નામ',
        if (!draft.hasAmounts) 'ઓછામાં ઓછો એક ખર્ચ',
      ];
      showAppSnack(context, '${missing.join(', ')} ઉમેરો',
          type: SnackType.error);
      if (!draft.hasName) {
        _scroll.animateTo(0,
            duration: Motion.of(context, Motion.medium),
            curve: Motion.emphasized);
      }
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(_draft.notifier);
    final costing = notifier.toSave();
    try {
      await ref
          .read(costingsProvider(widget.clientGuid).notifier)
          .save(costing);
      notifier.markSaved();
      unawaited(HapticFeedback.lightImpact());
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => QuoteScreen(
          costing: costing,
          clientName: widget.clientName,
          justSaved: true,
        ),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, 'સેવ ન થયું · Could not save',
          type: SnackType.error);
    }
  }

  void _bargain() {
    final breakdown = ref.read(_draft).breakdown;
    if (breakdown.totalExpense <= 0) {
      showAppSnack(context, 'પહેલાં ખર્ચ લખો · Enter the costs first');
      return;
    }
    showBargainSheet(
      context,
      breakdown: breakdown,
      applyLabel: 'આ ભાવ રાખો · Use this price',
      onApply: (profit) => ref.read(_draft.notifier).setProfit(profit),
    );
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ફેરફાર સેવ નથી થયા'),
        content: const Text(
            'તમે કરેલા ફેરફાર ગુમ થઈ જશે.\nYour changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('રહેવા દો'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('છોડી દો'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dirty = ref.watch(_draft.select((d) => d.dirty));
    final isNew = widget.costing == null;
    final existing = widget.costing ?? widget.copyOf;

    bool open(CostSection section) {
      if (existing == null) {
        return section == CostSection.patti || section == CostSection.labour;
      }
      return CostingCalculator.compute(existing).sectionTotal(section) != 0;
    }

    return PopScope(
      canPop: !dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard() && mounted) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: 'ભાવ-તાલ · Bargain',
              icon: const Icon(Icons.handshake_outlined),
              onPressed: _bargain,
            ),
          ],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isNew ? 'નવી કોસ્ટિંગ' : 'કોસ્ટિંગ સુધારો'),
              Text(
                widget.clientName,
                style: context.text.labelMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        bottomNavigationBar:
            TotalBar(draft: _draft, saving: _saving, onSave: _save),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            controller: _scroll,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              DesignHeader(draft: _draft, showErrors: _showErrors),
              const SizedBox(height: 14),
              for (final part in const [PartType.patti, PartType.buta]) ...[
                SectionCard(
                  draft: _draft,
                  label: Labels.sections[part == PartType.patti
                      ? CostSection.patti
                      : CostSection.buta]!,
                  icon: part == PartType.patti
                      ? Icons.diamond_outlined
                      : Icons.auto_awesome_outlined,
                  initiallyExpanded: open(part == PartType.patti
                      ? CostSection.patti
                      : CostSection.buta),
                  subtotal: (d) => d.breakdown.sectionTotal(
                      part == PartType.patti
                          ? CostSection.patti
                          : CostSection.buta),
                  children: [
                    for (final type in diamondOrder)
                      DiamondRow(draft: _draft, part: part, type: type),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              SectionCard(
                draft: _draft,
                label: Labels.sections[CostSection.sagadi]!,
                icon: Icons.local_fire_department_outlined,
                initiallyExpanded: open(CostSection.sagadi),
                subtotal: (d) => d.breakdown.sectionTotal(CostSection.sagadi),
                children: [
                  for (final type in sagadiOrder)
                    SagadiRow(draft: _draft, type: type),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                draft: _draft,
                label: Labels.sections[CostSection.labour]!,
                icon: Icons.handyman_outlined,
                initiallyExpanded: open(CostSection.labour),
                subtotal: (d) => d.breakdown.sectionTotal(CostSection.labour),
                children: [
                  for (final charge in FixedCharge.values)
                    FixedChargeRow(draft: _draft, charge: charge),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                draft: _draft,
                label: Labels.margins,
                icon: Icons.trending_up_rounded,
                initiallyExpanded: true,
                subtotal: (d) =>
                    d.breakdown.vatavAmount + d.breakdown.profitAmount,
                children: [
                  PercentRow(
                    draft: _draft,
                    label: Labels.vatav,
                    basisHint: 'ખર્ચ પર',
                    presets: const [1, 2, 3, 5],
                    percentage: (d) => d.costing.vatavPercentage ?? 0,
                    amount: (d) => d.breakdown.vatavAmount,
                    onChanged: (n, v) => n.setVatav(v),
                  ),
                  PercentRow(
                    draft: _draft,
                    label: Labels.profit,
                    basisHint: 'ખર્ચ + વટાવ પર',
                    presets: const [5, 10, 15, 20],
                    percentage: (d) => d.costing.profitPercentage ?? 0,
                    amount: (d) => d.breakdown.profitAmount,
                    onChanged: (n, v) => n.setProfit(v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
