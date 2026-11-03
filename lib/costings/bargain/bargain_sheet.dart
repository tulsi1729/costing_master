import 'package:costing_master/costings/calculator/widgets/num_field.dart';
import 'package:costing_master/domain/bargain.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/money.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:flutter/material.dart';

/// "The vepari says ₹450, can I do it?" Shows the profit at the trader's
/// price and, on apply, hands back the profit % that makes it the price.
Future<void> showBargainSheet(
  BuildContext context, {
  required CostingBreakdown breakdown,
  required String applyLabel,
  required ValueChanged<double> onApply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _BargainSheet(
      breakdown: breakdown,
      applyLabel: applyLabel,
      onApply: onApply,
    ),
  );
}

class _BargainSheet extends StatefulWidget {
  final CostingBreakdown breakdown;
  final String applyLabel;
  final ValueChanged<double> onApply;

  const _BargainSheet({
    required this.breakdown,
    required this.applyLabel,
    required this.onApply,
  });

  @override
  State<_BargainSheet> createState() => _BargainSheetState();
}

class _BargainSheetState extends State<_BargainSheet> {
  final _offer = TextEditingController();
  late final _suggestions = Bargain.suggestions(widget.breakdown.grandTotal);

  @override
  void dispose() {
    _offer.dispose();
    super.dispose();
  }

  void _pick(double offer) {
    _offer.text = formatInput(offer);
    _offer.selection = TextSelection.collapsed(offset: _offer.text.length);
    setState(() {});
  }

  void _apply(Bargain bargain) {
    Navigator.pop(context);
    widget.onApply(bargain.profitPercentage);
  }

  @override
  Widget build(BuildContext context) {
    final offer = parseAmount(_offer.text);
    final bargain = offer > 0 ? Bargain.of(widget.breakdown, offer) : null;
    final loss = bargain?.verdict == BargainVerdict.loss;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ભાવ-તાલ · Bargain',
                style: context.text.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              'આપણો ભાવ ${formatRupees(widget.breakdown.grandTotal, decimals: 0)}'
              ' · Our price',
              style: context.text.bodyMedium
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            NumField(
              controller: _offer,
              label: 'વેપારીનો ભાવ · Trader offers',
              hint: '0',
              prefix: inrSymbol,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final suggestion in _suggestions)
                    ActionChip(
                      label: Text(formatRupees(suggestion, decimals: 0)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _pick(suggestion),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: Motion.of(context, Motion.fast),
              child: bargain == null
                  ? _Hint(floor: widget.breakdown.totalWithVatav)
                  : _Result(bargain: bargain),
            ),
            const SizedBox(height: 16),
            if (loss)
              FilledButton.tonal(
                onPressed: () => _apply(bargain!),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.errorContainer,
                  foregroundColor: context.colors.onErrorContainer,
                ),
                child: Text('નુકસાનમાં પણ ${widget.applyLabel}'),
              )
            else
              FilledButton(
                onPressed: bargain == null ? null : () => _apply(bargain),
                child: Text(widget.applyLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final double floor;
  const _Hint({required this.floor});

  @override
  Widget build(BuildContext context) {
    return Text(
      'વેપારી જે ભાવ કહે તે લખો – તરત જ નફો દેખાશે.\n'
      'ઓછામાં ઓછો ભાવ ${formatRupees(floor, decimals: 0)} (ખર્ચ + વટાવ)',
      style: context.text.bodyMedium
          ?.copyWith(color: context.colors.onSurfaceVariant),
    );
  }
}

class _Result extends StatelessWidget {
  final Bargain bargain;
  const _Result({required this.bargain});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (background, foreground, icon, title) = switch (bargain.verdict) {
      BargainVerdict.good => (
          colors.primaryContainer,
          colors.onPrimaryContainer,
          Icons.check_circle_rounded,
          'આ ભાવ ચાલશે · Good deal',
        ),
      // Amber reads as "careful" in any palette; tertiary can be pink.
      BargainVerdict.thin => dark
          ? (
              const Color(0xFF4A3800),
              const Color(0xFFFFE08A),
              Icons.info_rounded,
              'નફો ઓછો છે · Thin margin',
            )
          : (
              const Color(0xFFFFEDC2),
              const Color(0xFF4F3B00),
              Icons.info_rounded,
              'નફો ઓછો છે · Thin margin',
            ),
      BargainVerdict.loss => (
          colors.errorContainer,
          colors.onErrorContainer,
          Icons.warning_rounded,
          'આ ભાવે નુકસાન · Loss',
        ),
    };
    final textStyle = TextStyle(color: foreground);
    String money(double value) => formatRupees(value, decimals: 0);

    return AnimatedContainer(
      duration: Motion.of(context, Motion.fast),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: textStyle.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${bargain.profit < 0 ? 'નુકસાન' : 'નફો'} '
            '${money(bargain.profit.abs())} '
            '(${bargain.profitPercentage.abs().toStringAsFixed(1)}%)',
            style: textStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (bargain.discount > 0)
            Text(
              'છૂટ ${money(bargain.discount)} '
              '(${bargain.discountPercentage.toStringAsFixed(1)}%) · Discount',
              style: textStyle,
            ),
          Text(
            'ઓછામાં ઓછો ભાવ ${money(bargain.floor)} · Lowest safe price',
            style: textStyle,
          ),
        ],
      ),
    );
  }
}
