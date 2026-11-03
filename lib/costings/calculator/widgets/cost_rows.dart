import 'package:costing_master/common/enums.dart';
import 'package:costing_master/costings/calculator/costing_draft.dart';
import 'package:costing_master/costings/calculator/widgets/num_field.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/labels.dart';
import 'package:costing_master/domain/money.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/animated_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared frame for a row: title, live amount and the input fields below.
/// Only this row rebuilds when its own amount changes.
class _RowShell extends ConsumerWidget {
  final DraftProvider draft;
  final Label label;
  final double Function(CostingDraft) amount;
  final Widget fields;

  const _RowShell({
    required this.draft,
    required this.label,
    required this.amount,
    required this.fields,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(draft.select(amount));
    final active = value != 0;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: active
            ? context.colors.primaryContainer.withValues(alpha: 0.45)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: label.gu,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: '  ${label.en}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ]),
                ),
              ),
              AnimatedAmount(
                value,
                animate: false,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color:
                      active ? context.colors.primary : context.colors.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          fields,
        ],
      ),
    );
  }
}

/// `diamonds per part × parts × rate per 100`
class DiamondRow extends ConsumerStatefulWidget {
  final DraftProvider draft;
  final PartType part;
  final DiamondType type;

  const DiamondRow({
    super.key,
    required this.draft,
    required this.part,
    required this.type,
  });

  @override
  ConsumerState<DiamondRow> createState() => _DiamondRowState();
}

class _DiamondRowState extends ConsumerState<DiamondRow> {
  late final TextEditingController _perPart;
  late final TextEditingController _parts;
  late final TextEditingController _rate;

  @override
  void initState() {
    super.initState();
    final d = ref.read(widget.draft).diamond(widget.part, widget.type);
    _perPart = TextEditingController(text: formatInput(d?.diamondsPerPart));
    _parts = TextEditingController(text: formatInput(d?.numbersOfPartsPerSari));
    _rate = TextEditingController(
        text: formatInput(d == null ? null : d.diamondRate * diamondRateUnit));
  }

  @override
  void dispose() {
    _perPart.dispose();
    _parts.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _changed(String _) {
    ref.read(widget.draft.notifier).setDiamond(
          widget.part,
          widget.type,
          perPart: parseAmount(_perPart.text).toInt(),
          parts: parseAmount(_parts.text),
          ratePer100: parseAmount(_rate.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final part = Labels.partNames[widget.part]!;
    return _RowShell(
      draft: widget.draft,
      label: Labels.diamondNames[widget.type]!,
      amount: (d) =>
          CostingCalculator.diamondAmount(d.diamond(widget.part, widget.type)),
      fields: Row(
        children: [
          Expanded(
            child: NumField(
              controller: _perPart,
              label: 'એક ${part.gu}માં',
              hint: '0',
              integer: true,
              onChanged: _changed,
            ),
          ),
          const OpGlyph('×'),
          Expanded(
            child: NumField(
              controller: _parts,
              label: '${part.gu} સંખ્યા',
              hint: '0',
              onChanged: _changed,
            ),
          ),
          const OpGlyph('×'),
          Expanded(
            child: NumField(
              controller: _rate,
              label: '100 નો ભાવ',
              hint: '0',
              prefix: inrSymbol,
              onChanged: _changed,
            ),
          ),
        ],
      ),
    );
  }
}

/// `items × charge per item`
class SagadiRow extends ConsumerStatefulWidget {
  final DraftProvider draft;
  final SagadiItemType type;

  const SagadiRow({super.key, required this.draft, required this.type});

  @override
  ConsumerState<SagadiRow> createState() => _SagadiRowState();
}

class _SagadiRowState extends ConsumerState<SagadiRow> {
  late final TextEditingController _count;
  late final TextEditingController _rate;

  @override
  void initState() {
    super.initState();
    final s = ref.read(widget.draft).sagadi(widget.type);
    _count = TextEditingController(text: formatInput(s?.itemsCount));
    _rate = TextEditingController(text: formatInput(s?.chargePerItem));
  }

  @override
  void dispose() {
    _count.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _changed(String _) {
    ref.read(widget.draft.notifier).setSagadi(
          widget.type,
          count: parseAmount(_count.text),
          rate: parseAmount(_rate.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return _RowShell(
      draft: widget.draft,
      label: Labels.sagadiNames[widget.type]!,
      amount: (d) => CostingCalculator.sagadiAmount(d.sagadi(widget.type)),
      fields: Row(
        children: [
          Expanded(
            child: NumField(
              controller: _count,
              label: 'સંખ્યા',
              hint: '0',
              onChanged: _changed,
            ),
          ),
          const OpGlyph('×'),
          Expanded(
            child: NumField(
              controller: _rate,
              label: 'મજૂરી',
              hint: '0',
              prefix: inrSymbol,
              onChanged: _changed,
            ),
          ),
        ],
      ),
    );
  }
}

/// A lump-sum labour charge.
class FixedChargeRow extends ConsumerStatefulWidget {
  final DraftProvider draft;
  final FixedCharge charge;

  const FixedChargeRow({super.key, required this.draft, required this.charge});

  @override
  ConsumerState<FixedChargeRow> createState() => _FixedChargeRowState();
}

class _FixedChargeRowState extends ConsumerState<FixedChargeRow> {
  late final TextEditingController _amount = TextEditingController(
    text: formatInput(CostingCalculator.fixedAmount(
        ref.read(widget.draft).costing, widget.charge)),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = Labels.fixedCharges[widget.charge]!;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: NumField(
        controller: _amount,
        label: label.gu,
        hint: label.en,
        prefix: inrSymbol,
        onChanged: (text) => ref
            .read(widget.draft.notifier)
            .setFixed(widget.charge, parseAmount(text)),
      ),
    );
  }
}

/// A percentage input with quick-pick chips and its computed amount.
class PercentRow extends ConsumerStatefulWidget {
  final DraftProvider draft;
  final Label label;
  final String basisHint;
  final List<double> presets;
  final double Function(CostingDraft) percentage;
  final double Function(CostingDraft) amount;
  final void Function(CostingDraftNotifier, double) onChanged;

  const PercentRow({
    super.key,
    required this.draft,
    required this.label,
    required this.basisHint,
    required this.presets,
    required this.percentage,
    required this.amount,
    required this.onChanged,
  });

  @override
  ConsumerState<PercentRow> createState() => _PercentRowState();
}

class _PercentRowState extends ConsumerState<PercentRow> {
  late final TextEditingController _controller = TextEditingController(
      text: formatInput(widget.percentage(ref.read(widget.draft))));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(double value) =>
      widget.onChanged(ref.read(widget.draft.notifier), value);

  @override
  Widget build(BuildContext context) {
    // Shows values set from elsewhere (e.g. the bargain helper), without
    // touching the field while the user's own typing already matches.
    ref.listen(widget.draft.select(widget.percentage), (_, value) {
      if (parseAmount(_controller.text) != value) {
        _controller.text = formatInput(value);
      }
    });
    final current = ref.watch(widget.draft.select(widget.percentage));
    return _RowShell(
      draft: widget.draft,
      label: widget.label,
      amount: widget.amount,
      fields: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NumField(
            controller: _controller,
            label: '% (${widget.basisHint})',
            hint: '0',
            suffix: '%',
            onChanged: (text) => _set(parseAmount(text)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final preset in widget.presets)
                ChoiceChip(
                  label: Text('${formatInput(preset)}%'),
                  selected: current == preset,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    _controller.text = formatInput(preset);
                    _set(preset);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
