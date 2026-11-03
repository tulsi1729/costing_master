import 'dart:async';
import 'dart:io';

import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/client/notifier/client_notifier.dart';
import 'package:costing_master/client/screen/client_form_screen.dart';
import 'package:costing_master/client/widgets/delete_client.dart';
import 'package:costing_master/costings/calculator/costing_calculator_screen.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/costings/quote/quote_screen.dart';
import 'package:costing_master/domain/costing_calculator.dart';
import 'package:costing_master/domain/money.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/storage/image_storage.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:costing_master/widgets/empty_state.dart';
import 'package:costing_master/widgets/entrance.dart';
import 'package:costing_master/widgets/network_thumb.dart';
import 'package:costing_master/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

enum _Sort { newest, price, designNo }

/// A client's designs as a searchable grid of photo cards.
class CostingListing extends ConsumerStatefulWidget {
  final Client client;

  const CostingListing({super.key, required this.client});

  @override
  ConsumerState<CostingListing> createState() => _CostingListingState();
}

class _CostingListingState extends ConsumerState<CostingListing> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
  _Sort _sort = _Sort.newest;
  bool _animateEntrance = true;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = text.trim().toLowerCase());
    });
  }

  List<Costing> _visible(List<Costing> all) {
    final filtered = _query.isEmpty
        ? [...all]
        : all
            .where((c) =>
                c.sariName.toLowerCase().contains(_query) ||
                (c.designNo?.toString().contains(_query) ?? false))
            .toList();
    switch (_sort) {
      case _Sort.newest:
        filtered.sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
      case _Sort.price:
        filtered.sort((a, b) => _price(b).compareTo(_price(a)));
      case _Sort.designNo:
        filtered.sort(
            (a, b) => (a.designNo ?? 1 << 30).compareTo(b.designNo ?? 1 << 30));
    }
    return filtered;
  }

  static double _price(Costing c) => CostingCalculator.compute(c).grandTotal;

  /// The client as last saved; edits made from this page show up here.
  Client get _client =>
      ref
          .read(clientsProvider)
          .value
          ?.where((c) => c.guid == widget.client.guid)
          .firstOrNull ??
      widget.client;

  Widget _calculator({Costing? costing, Costing? copyOf}) =>
      CostingCalculatorScreen(
        clientGuid: _client.guid,
        clientName: _client.name,
        userUid: ref.read(authProvider).value?.uid ?? _client.createdBy,
        costing: costing,
        copyOf: copyOf,
      );

  void _openCalculator({Costing? costing, Costing? copyOf}) {
    _animateEntrance = false;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _calculator(costing: costing, copyOf: copyOf)));
  }

  Future<void> _duplicate(Costing costing) async {
    var copy = costing;
    // Each costing needs its own phone photo: it is removed once backed up.
    if (LocalImages.isLocal(costing.imageUrl)) {
      try {
        copy = costing.copyWith(
            imageUrl: await LocalImages.save(LocalImages.file(costing.imageUrl),
                'copy_${DateTime.now().millisecondsSinceEpoch}'));
      } on FileSystemException {
        copy = costing.copyWith(imageUrl: '');
      }
    }
    if (mounted) _openCalculator(copyOf: copy);
  }

  Future<void> _delete(Costing costing) async {
    final notifier = ref.read(costingsProvider(_client.guid).notifier);
    try {
      await notifier.delete(costing);
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'ડિલીટ ન થયું · Could not delete',
            type: SnackType.error);
      }
      return;
    }
    if (!mounted) return;
    final name = costing.sariName.isEmpty ? 'કોસ્ટિંગ' : costing.sariName;
    showAppSnack(
      context,
      '$name ડિલીટ થઈ',
      action: SnackBarAction(
        label: 'પાછું લાવો',
        onPressed: () => notifier.restore(costing).ignore(),
      ),
    );
  }

  Future<void> _clientMenu(_ClientMenu action) async {
    switch (action) {
      case _ClientMenu.edit:
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ClientFormScreen(client: _client)));
      case _ClientMenu.delete:
        final navigator = Navigator.of(context);
        if (await deleteClientWithUndo(context, ref, _client)) navigator.pop();
    }
  }

  Future<void> _whatsApp(String phone) async {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    // Indian numbers are usually saved without the country code.
    if (digits.length == 10) digits = '91$digits';
    final opened = await launchUrl(Uri.parse('https://wa.me/$digits'),
        mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      showAppSnack(context, 'WhatsApp ખૂલ્યું નહીં', type: SnackType.error);
    }
  }

  void _openQuote(Costing costing) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuoteScreen(costing: costing, clientName: _client.name),
    ));
  }

  Future<void> _showActions(Costing costing) async {
    unawaited(HapticFeedback.selectionClick());
    final action = await showModalBottomSheet<_CostingAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('કોસ્ટિંગ જુઓ / શેર કરો'),
              subtitle: const Text('View & share quote'),
              onTap: () => Navigator.pop(context, _CostingAction.quote),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('સુધારો'),
              subtitle: const Text('Edit costing'),
              onTap: () => Navigator.pop(context, _CostingAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('નકલ બનાવો'),
              subtitle: const Text('Duplicate as a new costing'),
              onTap: () => Navigator.pop(context, _CostingAction.duplicate),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: context.colors.error),
              title: const Text('ડિલીટ કરો'),
              subtitle: const Text('Delete costing'),
              onTap: () => Navigator.pop(context, _CostingAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _CostingAction.quote:
        _openQuote(costing);
      case _CostingAction.edit:
        _openCalculator(costing: costing);
      case _CostingAction.duplicate:
        await _duplicate(costing);
      case _CostingAction.delete:
        await _delete(costing);
      case null:
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = costingsProvider(widget.client.guid);
    final costings = ref.watch(provider);
    final count = costings.value?.length;
    final client = ref.watch(clientsProvider.select((all) =>
        all.value?.where((c) => c.guid == widget.client.guid).firstOrNull ??
        widget.client));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCalculator(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('નવી કોસ્ટિંગ'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(provider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name),
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.fast),
                    child: Text(
                      count == null ? ' ' : '$count ડિઝાઇન',
                      key: ValueKey(count),
                      style: context.text.labelMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              actions: [
                if (client.phone.isNotEmpty)
                  IconButton(
                    tooltip: 'WhatsApp',
                    icon: const Icon(Icons.chat_outlined),
                    onPressed: () => _whatsApp(client.phone),
                  ),
                PopupMenuButton<_ClientMenu>(
                  tooltip: 'વેપારી · Trader',
                  onSelected: _clientMenu,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _ClientMenu.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('વેપારી સુધારો'),
                        subtitle: Text('Edit trader'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ClientMenu.delete,
                      child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded,
                            color: context.colors.error),
                        title: const Text('વેપારી ડિલીટ કરો'),
                        subtitle: const Text('Delete trader'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearch,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'નામ કે ડિઝાઇન નંબર',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<_Sort>(
                      tooltip: 'Sort',
                      initialValue: _sort,
                      onSelected: (s) => setState(() => _sort = s),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: _Sort.newest,
                            child: Text('નવી પહેલા · Newest')),
                        PopupMenuItem(
                            value: _Sort.price, child: Text('ભાવ · Price')),
                        PopupMenuItem(
                            value: _Sort.designNo,
                            child: Text('ડિઝાઇન નંબર · Design no.')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.sort_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...switch (costings) {
              AsyncValue(:final value?) => _grid(value),
              AsyncError() => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'કોસ્ટિંગ લોડ ન થઈ',
                      message: 'ફરી પ્રયત્ન કરો · Please try again',
                      actionLabel: 'ફરી પ્રયત્ન કરો',
                      onAction: () => ref.invalidate(provider),
                    ),
                  ),
                ],
              _ => [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid.builder(
                      gridDelegate: _gridDelegate,
                      itemCount: 6,
                      itemBuilder: (_, __) => const Skeleton(
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                    ),
                  ),
                ],
            },
          ],
        ),
      ),
    );
  }

  static const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 240,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.68,
  );

  List<Widget> _grid(List<Costing> all) {
    if (all.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.diamond_outlined,
            title: 'હજુ કોઈ કોસ્ટિંગ નથી',
            message: 'નીચે "નવી કોસ્ટિંગ" દબાવીને પહેલી ડિઝાઇનનો ભાવ કાઢો.',
          ),
        ),
      ];
    }
    final visible = _visible(all);
    if (visible.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'કંઈ મળ્યું નહીં',
            message: 'બીજું નામ અથવા ડિઝાઇન નંબર અજમાવો',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        sliver: SliverGrid.builder(
          gridDelegate: _gridDelegate,
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final costing = visible[index];
            return Entrance(
              key: ValueKey(costing.guid),
              index: index,
              enabled: _animateEntrance,
              child: _DesignCard(
                costing: costing,
                onTap: () => _openCalculator(costing: costing),
                onLongPress: () => _showActions(costing),
                onShare: () => _openQuote(costing),
              ),
            );
          },
        ),
      ),
    ];
  }
}

enum _CostingAction { quote, edit, duplicate, delete }

enum _ClientMenu { edit, delete }

class _DesignCard extends StatelessWidget {
  final Costing costing;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onShare;

  const _DesignCard({
    required this.costing,
    required this.onTap,
    required this.onLongPress,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final price = CostingCalculator.compute(costing).grandTotal;
    return RepaintBoundary(
      child: Card(
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkThumb(url: costing.imageUrl),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'શેર · Share',
                          visualDensity: VisualDensity.compact,
                          onPressed: onShare,
                          icon: const Icon(Icons.ios_share_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    if (costing.designNo != null)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${costing.designNo}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      costing.sariName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupees(price),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: context.colors.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
