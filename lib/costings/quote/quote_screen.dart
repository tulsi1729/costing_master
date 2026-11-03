import 'dart:async';

import 'package:costing_master/costings/bargain/bargain_sheet.dart';
import 'package:costing_master/costings/calculator/costing_calculator_screen.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/costings/quote/quote_card.dart';
import 'package:costing_master/costings/quote/quote_export.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/money.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/settings/app_settings.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/settings/screens/business_profile_screen.dart';
import 'package:costing_master/settings/screens/quote_design_screen.dart';
import 'package:costing_master/sync/backup_nudge.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuoteScreen extends ConsumerStatefulWidget {
  final Costing costing;
  final String clientName;
  final bool justSaved;

  const QuoteScreen({
    super.key,
    required this.costing,
    required this.clientName,
    this.justSaved = false,
  });

  @override
  ConsumerState<QuoteScreen> createState() => _QuoteScreenState();
}

enum _Busy { none, share, save, pdf }

class _QuoteScreenState extends ConsumerState<QuoteScreen> {
  final _boundary = GlobalKey();
  final _shareButton = GlobalKey();
  QuoteMode _mode = QuoteMode.customer;
  _Busy _busy = _Busy.none;

  String get _fileName =>
      QuoteExport.fileName(widget.costing.sariName, widget.costing.designNo);

  @override
  void initState() {
    super.initState();
    if (widget.justSaved) {
      // Let the "saved" moment land first, and never stack two asks: the
      // business-profile prompt takes priority when it is showing.
      Future.delayed(const Duration(milliseconds: 900), () {
        final settings = ref.read(settingsProvider).value;
        final profilePrompt = settings != null &&
            settings.profile.isEmpty &&
            !settings.profilePrompted;
        if (mounted && !profilePrompt) maybeShowBackupNudge(context, ref);
      });
    }
  }

  Future<void> _run(_Busy kind, Future<void> Function() action) async {
    if (_busy != _Busy.none) return;
    setState(() => _busy = kind);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'કંઈક ખોટું થયું, ફરી પ્રયત્ન કરો',
            type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = _Busy.none);
    }
  }

  String get _shareText {
    final grand = CostingCalculator.compute(widget.costing).grandTotal;
    return '${widget.costing.sariName} – ${formatRupees(grand)}\n'
        'Made with કોસ્ટિંગ માસ્ટર: $playStoreUrl';
  }

  Rect? get _shareOrigin {
    final box = _shareButton.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _share() => _run(_Busy.share, () async {
        final png = await QuoteExport.capture(_boundary);
        await QuoteExport.share(png,
            fileName: _fileName, text: _shareText, origin: _shareOrigin);
      });

  Future<void> _sharePdf() => _run(_Busy.pdf, () async {
        final png = await QuoteExport.capture(_boundary);
        await QuoteExport.sharePdf(png,
            fileName: _fileName, text: _shareText, origin: _shareOrigin);
      });

  Future<void> _saveToGallery() => _run(_Busy.save, () async {
        final png = await QuoteExport.capture(_boundary);
        final ok = await QuoteExport.saveToGallery(png, name: _fileName);
        if (!mounted) return;
        unawaited(HapticFeedback.lightImpact());
        showAppSnack(
          context,
          ok ? 'ગેલેરીમાં સેવ થયું · Saved to gallery' : 'સેવ ન થયું',
          type: ok ? SnackType.success : SnackType.error,
        );
      });

  void _edit() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => CostingCalculatorScreen(
        clientGuid: widget.costing.clientGuid,
        clientName: widget.clientName,
        userUid: widget.costing.createdBy,
        costing: widget.costing,
      ),
    ));
  }

  void _bargain() => showBargainSheet(
        context,
        breakdown: CostingCalculator.compute(widget.costing),
        applyLabel: 'આ ભાવે સેવ કરો · Save at this price',
        onApply: _saveWithProfit,
      );

  /// Saves the costing at the agreed price and shows its updated quote.
  Future<void> _saveWithProfit(double profitPercentage) async {
    final costing = CostingCalculator.withTotals(widget.costing.copyWith(
      profitPercentage: profitPercentage,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    try {
      await ref
          .read(costingsProvider(costing.clientGuid).notifier)
          .save(costing);
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'સેવ ન થયું · Could not save',
            type: SnackType.error);
      }
      return;
    }
    if (!mounted) return;
    final price = CostingCalculator.compute(costing).grandTotal;
    showAppSnack(context, '${formatRupees(price, decimals: 0)} પર સેવ થયું',
        type: SnackType.success);
    await Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) =>
          QuoteScreen(costing: costing, clientName: widget.clientName),
    ));
  }

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final showProfilePrompt = widget.justSaved &&
        settings.profile.isEmpty &&
        !settings.profilePrompted;
    final updatedAt = widget.costing.updatedAt;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.costing.sariName),
        actions: [
          IconButton(
            tooltip: 'સુધારો · Edit',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'ડિઝાઇન · Quote style',
            onPressed: () => _open(const QuoteDesignScreen()),
            icon: const Icon(Icons.palette_outlined),
          ),
          IconButton(
            tooltip: 'PDF',
            onPressed: _busy == _Busy.none ? _sharePdf : null,
            icon: _busy == _Busy.pdf
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (widget.justSaved) const _SavedChip(),
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.emphasized,
            child: showProfilePrompt
                ? _ProfilePrompt(
                    onAdd: () {
                      ref
                          .read(settingsProvider.notifier)
                          .edit((s) => s.copyWith(profilePrompted: true));
                      _open(const BusinessProfileScreen());
                    },
                    onDismiss: () => ref
                        .read(settingsProvider.notifier)
                        .edit((s) => s.copyWith(profilePrompted: true)),
                  )
                : const SizedBox(width: double.infinity),
          ),
          SegmentedButton<QuoteMode>(
            segments: const [
              ButtonSegment(
                value: QuoteMode.customer,
                icon: Icon(Icons.storefront_outlined),
                label: Text('વેપારી માટે'),
              ),
              ButtonSegment(
                value: QuoteMode.internal,
                icon: Icon(Icons.lock_outline_rounded),
                label: Text('મારા માટે'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 12),
            child: Text(
              _mode == QuoteMode.customer
                  ? 'વટાવ અને નફો ભાવમાં સમાવેલ છે – વેપારીને દેખાશે નહીં'
                  : 'સંપૂર્ણ હિસાબ વટાવ અને નફા સાથે – ફક્ત તમારા માટે',
              textAlign: TextAlign.center,
              style: context.text.bodySmall
                  ?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
          FittedBox(
            fit: BoxFit.fitWidth,
            child: RepaintBoundary(
              key: _boundary,
              child: AnimatedSwitcher(
                duration: Motion.of(context, Motion.medium),
                child: QuoteCard(
                  key: ValueKey(_mode),
                  costing: widget.costing,
                  clientName: widget.clientName,
                  profile: settings.profile,
                  style: settings.quoteStyle,
                  mode: _mode,
                  date: updatedAt == null
                      ? DateTime.now()
                      : DateTime.fromMillisecondsSinceEpoch(updatedAt),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.tonalIcon(
                onPressed: _busy == _Busy.none ? _bargain : null,
                icon: const Icon(Icons.handshake_outlined),
                label: const Text('વેપારી ઓછો ભાવ કહે છે? · Bargain'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy == _Busy.none ? _saveToGallery : null,
                      icon: _busy == _Busy.save
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.download_rounded),
                      label: const Text('ગેલેરી'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: _shareButton,
                      onPressed: _busy == _Busy.none ? _share : null,
                      icon: _busy == _Busy.share
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.colors.onPrimary))
                          : const Icon(Icons.share_rounded),
                      label: const Text('શેર કરો · WhatsApp'),
                    ),
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

class _SavedChip extends StatelessWidget {
  const _SavedChip();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, const Duration(milliseconds: 600)),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32), size: 20),
              SizedBox(width: 8),
              Text(
                'કોસ્ટિંગ સેવ થઈ ગઈ',
                style: TextStyle(
                    color: Color(0xFF2E7D32), fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePrompt extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  const _ProfilePrompt({required this.onAdd, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.primaryContainer,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: context.colors.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'તમારા બિઝનેસનું નામ ઉમેરો – કોસ્ટિંગ પર દેખાશે',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 34, top: 2),
              child: Text(
                'Your name, logo and phone on every quote you share.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: context.colors.onPrimaryContainer
                        .withValues(alpha: 0.8)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDismiss, child: const Text('પછી')),
                FilledButton.tonal(
                    onPressed: onAdd, child: const Text('ઉમેરો')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
