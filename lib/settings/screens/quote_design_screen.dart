import 'package:costing_master/common/enums.dart';
import 'package:costing_master/costings/quote/quote_card.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/model/diamond_costing.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/settings/widgets/settings_widgets.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Template, accent and what to show on shared quotes, with a live preview
/// so the user sees exactly what their customer will get.
class QuoteDesignScreen extends ConsumerWidget {
  const QuoteDesignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    return SettingsPage(
      title: 'કોસ્ટિંગની ડિઝાઇન',
      body: (settings) {
        final style = settings.quoteStyle;
        void setStyle(QuoteStyle s) => saveSettings(
            context, notifier, (all) => all.copyWith(quoteStyle: s));

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const SectionTitle('લાઇવ પ્રિવ્યૂ', 'Live preview of your quote'),
            _Preview(settings: settings),
            const SectionTitle('ટેમ્પ્લેટ', 'Template (મારા માટે)'),
            SegmentedButton<QuoteTemplate>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: QuoteTemplate.royal, label: Text('રોયલ')),
                ButtonSegment(
                    value: QuoteTemplate.classic, label: Text('ક્લાસિક')),
                ButtonSegment(
                    value: QuoteTemplate.minimal, label: Text('સાદી')),
              ],
              selected: {style.template},
              onSelectionChanged: (s) =>
                  setStyle(style.copyWith(template: s.first)),
            ),
            const SectionTitle('રંગ', 'Accent'),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (var i = 0; i < quoteAccents.length; i++)
                  ColorSwatchButton(
                    color: quoteAccents[i],
                    selected: style.accentIndex == i,
                    onTap: () => setStyle(style.copyWith(accentIndex: i)),
                  ),
              ],
            ),
            const SectionTitle('શું બતાવવું', 'Show on the quote'),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    SettingsToggle(
                        'ફોટો બતાવો',
                        'Show design photo',
                        style.showPhoto,
                        (v) => setStyle(style.copyWith(showPhoto: v))),
                    SettingsToggle(
                        'દરેક વસ્તુનો ભાવ',
                        'Item-wise rows (મારા માટે)',
                        style.showItems,
                        (v) => setStyle(style.copyWith(showItems: v))),
                    SettingsToggle('તારીખ', 'Show date', style.showDate,
                        (v) => setStyle(style.copyWith(showDate: v))),
                    SettingsToggle(
                        'ગુજરાતી અંક (૧૨૩)',
                        'Gujarati numerals',
                        style.gujaratiDigits,
                        (v) => setStyle(style.copyWith(gujaratiDigits: v))),
                    SettingsToggle(
                        '"Made with કોસ્ટિંગ માસ્ટર"',
                        'Small footer line',
                        style.showFooter,
                        (v) => setStyle(style.copyWith(showFooter: v))),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Live preview of either quote, so settings that only affect one of them
/// can still be seen.
class _Preview extends StatefulWidget {
  final AppSettings settings;

  const _Preview({required this.settings});

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  QuoteMode _mode = QuoteMode.customer;

  @override
  Widget build(BuildContext context) {
    final style = widget.settings.quoteStyle;
    return Column(
      children: [
        SegmentedButton<QuoteMode>(
          segments: const [
            ButtonSegment(
                value: QuoteMode.customer, label: Text('વેપારી માટે')),
            ButtonSegment(value: QuoteMode.internal, label: Text('મારા માટે')),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 300,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.medium),
                child: QuoteCard(
                  key: ValueKey((style, _mode)),
                  costing: _sampleCosting,
                  clientName: 'શ્રી ટેક્સટાઇલ્સ',
                  profile: widget.settings.profile,
                  style: style,
                  mode: _mode,
                  date: DateTime.now(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final _sampleCosting = Costing(
  guid: 'sample',
  createdBy: '',
  clientGuid: '',
  designNo: 108,
  sariName: 'રાની પટોળા',
  description: 'હાથ ભરતકામ, જરકન બોર્ડર',
  imageUrl: '',
  sheetBharvana: 60,
  lessFiting: 25,
  reniyaCutting: 10,
  fusing: 12,
  dieKapvana: 0,
  otherCost: 8,
  vatavPercentage: 2,
  profitPercentage: 12,
  totalExpense: 0,
  totalChargesPlusVatavAmount: 0,
  totalChargesPlusVatavPlusProfit: 0,
  diamondCostingsMap: {
    PartType.patti: {
      DiamondType.shadow: DiamondCosting(
        diamondType: DiamondType.shadow,
        partType: PartType.patti,
        diamondRate: 0.45,
        diamondsPerPart: 30,
        numbersOfPartsPerSari: 12,
      ),
    },
  },
  sagadiCostingsMap: {},
);
