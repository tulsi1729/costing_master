import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/labels.dart';
import 'package:costing_master/domain/money.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/brand_mark.dart';
import 'package:costing_master/widgets/network_thumb.dart';
import 'package:flutter/material.dart';

enum QuoteMode {
  /// Margins folded into the line prices; safe to send to a buyer.
  customer,

  /// Full breakdown with vatav and profit, for the owner.
  internal,
}

const playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.rightdevs.costing_master';

/// Logical width the quote is laid out at, independent of the device, so a
/// shared image looks identical from every phone.
const quoteWidth = 400.0;

/// The branded, shareable quote. Always rendered in light colours so the
/// exported image looks the same whatever theme the app is in.
class QuoteCard extends StatelessWidget {
  final Costing costing;
  final String clientName;
  final BusinessProfile profile;
  final QuoteStyle style;
  final QuoteMode mode;
  final DateTime date;

  const QuoteCard({
    super.key,
    required this.costing,
    required this.clientName,
    required this.profile,
    required this.style,
    required this.mode,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(AppColor.navy),
      child: Builder(builder: (context) => _build(context)),
    );
  }

  Widget _build(BuildContext context) {
    final breakdown = CostingCalculator.compute(costing);
    final accent = style.accent;
    const gold = quoteGold;
    final template = style.template;
    final digits = style.gujaratiDigits;
    String money(double v, {int decimals = 2}) =>
        formatRupees(v, decimals: decimals, gujaratiDigits: digits);
    String qty(num v) => formatQty(v, gujaratiDigits: digits);

    final lines = mode == QuoteMode.customer
        ? breakdown.customerLines
        : breakdown.pricedLines.toList();

    final border = switch (template) {
      QuoteTemplate.royal => Border.all(color: gold, width: 3),
      QuoteTemplate.classic => Border.all(color: accent.withValues(alpha: 0.4)),
      QuoteTemplate.minimal => Border.all(color: const Color(0xFFE0E0E0)),
    };

    return Container(
      width: quoteWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: border,
        borderRadius:
            BorderRadius.circular(template == QuoteTemplate.minimal ? 4 : 18),
      ),
      clipBehavior: Clip.antiAlias,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Color(0xFF1C1B1F), fontSize: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(profile: profile, style: style, gold: gold),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: _DesignInfo(
                costing: costing,
                clientName: clientName,
                accent: accent,
                date: style.showDate ? date : null,
                gujaratiDigits: digits,
                internal: mode == QuoteMode.internal,
              ),
            ),
            if (style.showPhoto && costing.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: SizedBox(
                  height: 230,
                  child: NetworkThumb(
                    url: costing.imageUrl,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (style.showItems && lines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _Lines(
                  lines: lines,
                  accent: accent,
                  money: money,
                  qty: qty,
                ),
              ),
            if (mode == QuoteMode.internal)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    const Divider(height: 16),
                    _LadderRow(
                        Labels.totalExpense.gu, money(breakdown.totalExpense),
                        strong: true),
                    _LadderRow(
                        '${Labels.vatav.gu} (${formatInput(breakdown.vatavPercentage)}%)',
                        money(breakdown.vatavAmount)),
                    _LadderRow(Labels.totalWithVatav.gu,
                        money(breakdown.totalWithVatav)),
                    _LadderRow(
                        '${Labels.profit.gu} (${formatInput(breakdown.profitPercentage)}%)',
                        money(breakdown.profitAmount)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            _GrandTotal(
              amount: money(breakdown.grandTotal),
              template: template,
              accent: accent,
              gold: gold,
            ),
            if (style.showFooter) const _GrowthFooter(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final BusinessProfile profile;
  final QuoteStyle style;
  final Color gold;

  const _Header(
      {required this.profile, required this.style, required this.gold});

  @override
  Widget build(BuildContext context) {
    final accent = style.accent;
    final dark = style.template == QuoteTemplate.royal;
    final fg = dark ? Colors.white : accent;
    final title = profile.isEmpty ? 'કોસ્ટિંગ શીટ' : profile.businessName;
    final contact = [
      if (profile.ownerName.isNotEmpty) profile.ownerName,
      if (profile.phone.isNotEmpty) profile.phone,
      if (profile.city.isNotEmpty) profile.city,
    ].join('  ·  ');

    final Widget logo = profile.logoUrl.isNotEmpty
        ? ClipOval(
            child: SizedBox.square(
              dimension: 52,
              child: NetworkThumb(url: profile.logoUrl),
            ),
          )
        : profile.isEmpty
            ? const BrandMark(size: 52)
            : CircleAvatar(
                radius: 26,
                backgroundColor: dark ? gold : accent,
                child: Text(
                  profile.businessName.characters.first.toUpperCase(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: dark ? const Color(0xFF2B1F00) : Colors.white,
                  ),
                ),
              );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: switch (style.template) {
        QuoteTemplate.royal => BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, Color.lerp(accent, Colors.black, 0.35)!],
            ),
            border: Border(bottom: BorderSide(color: gold, width: 3)),
          ),
        QuoteTemplate.classic => BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            border: Border(bottom: BorderSide(color: accent, width: 4)),
          ),
        QuoteTemplate.minimal => const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
          ),
      },
      child: Row(
        children: [
          logo,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: style.template == QuoteTemplate.minimal
                        ? const Color(0xFF1C1B1F)
                        : fg,
                  ),
                ),
                if (profile.tagline.isNotEmpty)
                  Text(
                    profile.tagline,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: dark ? gold : const Color(0xFF5F5B66),
                    ),
                  ),
                if (contact.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      contact,
                      style: TextStyle(
                        fontSize: 12,
                        color: dark
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF5F5B66),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignInfo extends StatelessWidget {
  final Costing costing;
  final String clientName;
  final Color accent;
  final DateTime? date;
  final bool gujaratiDigits;
  final bool internal;

  const _DesignInfo({
    required this.costing,
    required this.clientName,
    required this.accent,
    required this.date,
    required this.gujaratiDigits,
    required this.internal,
  });

  @override
  Widget build(BuildContext context) {
    String digits(String s) => gujaratiDigits ? toGujaratiDigits(s) : s;
    final d = date;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                costing.sariName,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            if (costing.designNo != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  digits('ડિઝાઇન #${costing.designNo}'),
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                'વેપારી: $clientName',
                style: const TextStyle(color: Color(0xFF5F5B66)),
              ),
            ),
            if (d != null)
              Text(
                digits('${d.day.toString().padLeft(2, '0')}/'
                    '${d.month.toString().padLeft(2, '0')}/${d.year}'),
                style:
                    const TextStyle(color: Color(0xFF5F5B66), fontSize: 12.5),
              ),
          ],
        ),
        if (internal)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'આંતરિક · Internal copy – વટાવ અને નફો સાથે',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB71C1C)),
              ),
            ),
          ),
      ],
    );
  }
}

class _Lines extends StatelessWidget {
  final List<BreakdownLine> lines;
  final Color accent;
  final String Function(double, {int decimals}) money;
  final String Function(num) qty;

  const _Lines({
    required this.lines,
    required this.accent,
    required this.money,
    required this.qty,
  });

  String _title(BreakdownLine line) {
    if (line.diamond != null) {
      return Labels.diamondLine(line.part!, line.diamond!);
    }
    if (line.sagadi != null) return Labels.sagadiNames[line.sagadi]!.gu;
    return Labels.fixedCharges[line.fixed]!.gu;
  }

  String? _detail(BreakdownLine line) {
    if (line.quantity == null || line.rate == null) return null;
    if (line.diamond != null) {
      return '${qty(line.quantity!)} નંગ × ${money(line.rate!)}/100';
    }
    return '${qty(line.quantity!)} × ${money(line.rate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    CostSection? current;
    for (final line in lines) {
      if (line.section != current) {
        current = line.section;
        children.add(Padding(
          padding: EdgeInsets.only(top: children.isEmpty ? 0 : 10, bottom: 4),
          child: Text(
            Labels.sections[current]!.gu.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ));
      }
      final detail = _detail(line);
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_title(line),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (detail != null)
                    Text(detail,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF79747E))),
                ],
              ),
            ),
            Text(
              money(line.amount),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _LadderRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _LadderRow(this.label, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    final weight = strong ? FontWeight.w800 : FontWeight.w500;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontWeight: weight))),
          Text(value,
              style: TextStyle(
                  fontWeight: weight,
                  fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class _GrandTotal extends StatelessWidget {
  final String amount;
  final QuoteTemplate template;
  final Color accent;
  final Color gold;

  const _GrandTotal({
    required this.amount,
    required this.template,
    required this.accent,
    required this.gold,
  });

  @override
  Widget build(BuildContext context) {
    final (decoration, fg) = switch (template) {
      QuoteTemplate.royal => (
          BoxDecoration(
            gradient: LinearGradient(colors: [
              gold,
              Color.lerp(gold, Colors.white, 0.35)!,
            ]),
          ),
          const Color(0xFF2B1F00),
        ),
      QuoteTemplate.classic => (BoxDecoration(color: accent), Colors.white),
      QuoteTemplate.minimal => (
          const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF1C1B1F), width: 2)),
          ),
          const Color(0xFF1C1B1F),
        ),
    };
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Labels.finalPrice.gu,
                    style: TextStyle(
                        color: fg, fontWeight: FontWeight.w700, fontSize: 16)),
                Text('પ્રતિ સાડી · per sari',
                    style: TextStyle(
                        color: fg.withValues(alpha: 0.75), fontSize: 11.5)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: fg,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthFooter extends StatelessWidget {
  const _GrowthFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BrandMark(size: 18),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Made with કોસ્ટિંગ માસ્ટર · Play Store',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Color(0xFF79747E)),
            ),
          ),
        ],
      ),
    );
  }
}
