import 'dart:async';

import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/client/notifier/client_notifier.dart';
import 'package:costing_master/client/notifier/home_summary.dart';
import 'package:costing_master/client/screen/client_form_screen.dart';
import 'package:costing_master/client/widgets/client_avatar.dart';
import 'package:costing_master/client/widgets/delete_client.dart';
import 'package:costing_master/client/widgets/how_it_works.dart';
import 'package:costing_master/client/widgets/recent_costings.dart';
import 'package:costing_master/costings/quote/quote_screen.dart';
import 'package:costing_master/costings/screens/costing_listing.dart';
import 'package:costing_master/domain/time_ago.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/settings/settings_screen.dart';
import 'package:costing_master/sync/backup_sheet.dart';
import 'package:costing_master/sync/sync_notifier.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/app_snack.dart';
import 'package:costing_master/widgets/brand_mark.dart';
import 'package:costing_master/widgets/empty_state.dart';
import 'package:costing_master/widgets/entrance.dart';
import 'package:costing_master/widgets/section_title.dart';
import 'package:costing_master/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientListing extends ConsumerStatefulWidget {
  const ClientListing({super.key});

  @override
  ConsumerState<ClientListing> createState() => _ClientListingState();
}

class _ClientListingState extends ConsumerState<ClientListing> {
  /// Search appears once the list is long enough to need it.
  static const _searchFrom = 6;

  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';
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

  void _openQuote(Costing costing, String? clientName) {
    _animateEntrance = false;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          QuoteScreen(costing: costing, clientName: clientName ?? ''),
    ));
  }

  void _openClient(Client client) {
    _animateEntrance = false;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CostingListing(client: client),
    ));
  }

  Future<void> _addClient() async {
    final created = await Navigator.of(context).push<Client>(
        MaterialPageRoute(builder: (_) => const ClientFormScreen()));
    if (created != null && mounted) {
      showAppSnack(context, '${created.name} ઉમેરાયા', type: SnackType.success);
    }
  }

  Future<void> _showActions(Client client) async {
    unawaited(HapticFeedback.selectionClick());
    final action = await showModalBottomSheet<_ClientAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('સુધારો'),
              subtitle: const Text('Edit name, phone, city'),
              onTap: () => Navigator.pop(context, _ClientAction.edit),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: context.colors.error),
              title: const Text('ડિલીટ કરો'),
              subtitle: const Text('Delete trader and costings'),
              onTap: () => Navigator.pop(context, _ClientAction.delete),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _ClientAction.edit:
        await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ClientFormScreen(client: client)));
      case _ClientAction.delete:
        await deleteClientWithUndo(context, ref, client);
      case null:
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(clientsProvider);
    final signedIn = ref.watch(authProvider.select((u) => u.value != null));
    final businessName = ref.watch(
        settingsProvider.select((s) => s.value?.profile.businessName ?? ''));
    final syncing = ref.watch(syncProvider.select((s) => s.syncing));
    final summary = ref.watch(homeSummaryProvider).value;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addClient,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('વેપારી ઉમેરો'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(clientsProvider.future),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              leading: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: BrandMark(size: 32),
              ),
              leadingWidth: 52,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName.isEmpty ? 'કોસ્ટિંગ માસ્ટર' : businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (summary != null && clients.value?.isNotEmpty == true)
                    Text(
                      '${clients.value!.length} વેપારી · '
                      '${summary.total} ડિઝાઇન · '
                      '${summary.thisMonth} આ મહિને',
                      style: context.text.labelMedium
                          ?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                ],
              ),
              actions: [
                if (!signedIn)
                  IconButton(
                    tooltip: 'બેકઅપ · Back up',
                    icon: const Icon(Icons.cloud_upload_outlined),
                    onPressed: () => showBackupSheet(context),
                  ),
                IconButton(
                  tooltip: 'સેટિંગ્સ · Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SettingsScreen())),
                ),
              ],
            ),
            ...switch (clients) {
              // An empty phone that is pulling its backup is still loading.
              AsyncValue(:final value?)
                  when !(value.isEmpty && signedIn && syncing) =>
                _clientSlivers(value, signedIn: signedIn, summary: summary),
              AsyncError() => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'વેપારીઓ લોડ ન થયા',
                      message: 'ફરી પ્રયત્ન કરો · Please try again',
                      actionLabel: 'ફરી પ્રયત્ન કરો',
                      onAction: () => ref.invalidate(clientsProvider),
                    ),
                  ),
                ],
              _ => [
                  SliverList.builder(
                    itemCount: 6,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Skeleton(height: 72),
                    ),
                  ),
                ],
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _clientSlivers(List<Client> all,
      {required bool signedIn, required HomeSummary? summary}) {
    if (all.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.groups_2_outlined,
            title: 'હજુ કોઈ વેપારી નથી',
            message: 'પહેલો વેપારી ઉમેરો અને તેમની સાડીની કોસ્ટિંગ બનાવો.',
            actionLabel: 'વેપારી ઉમેરો',
            onAction: _addClient,
            secondaryActionLabel:
                signedIn ? null : 'પહેલાં બેકઅપ કર્યું છે? પાછું લાવો',
            onSecondaryAction: () => showBackupSheet(context, restore: true),
          ),
        ),
      ];
    }
    final searchable = all.length > _searchFrom;
    final clients = !searchable || _query.isEmpty
        ? all
        : all.where((c) => c.name.toLowerCase().contains(_query)).toList();
    final names = {for (final c in all) c.guid: c.name};
    final recent = summary?.recent ?? const <Costing>[];

    return [
      if (summary?.total == 0)
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverToBoxAdapter(child: HowItWorks()),
        ),
      if (recent.isNotEmpty) ...[
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
              child: SectionTitle('તાજેતરની કોસ્ટિંગ', 'Recent')),
        ),
        SliverToBoxAdapter(
          child: RecentCostings(
            costings: recent,
            onOpen: (costing) => _openQuote(costing, names[costing.clientGuid]),
          ),
        ),
      ],
      const SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(child: SectionTitle('વેપારીઓ', 'Traders')),
      ),
      if (searchable)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'વેપારી શોધો · Search traders',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: _search,
                  builder: (_, value, __) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            _onSearch('');
                          },
                        ),
                ),
              ),
            ),
          ),
        ),
      if (clients.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'કોઈ વેપારી મળ્યા નહીં',
            message: '"${_search.text}" નામે કોઈ વેપારી નથી',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return Entrance(
                key: ValueKey(client.guid),
                index: index,
                enabled: _animateEntrance,
                child: _ClientTile(
                  client: client,
                  stats: summary?.byClient[client.guid],
                  first: index == 0,
                  last: index == clients.length - 1,
                  onTap: () => _openClient(client),
                  onLongPress: () => _showActions(client),
                ),
              );
            },
          ),
        ),
      // Room for the floating button over the last item.
      const SliverToBoxAdapter(child: SizedBox(height: 96)),
    ];
  }
}

enum _ClientAction { edit, delete }

/// One row of the grouped client list; [first] and [last] round the
/// group's corners and [last] drops the divider.
class _ClientTile extends StatelessWidget {
  final Client client;
  final ClientStats? stats;
  final bool first;
  final bool last;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ClientTile({
    required this.client,
    required this.stats,
    required this.first,
    required this.last,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final count = stats?.count ?? 0;
    final lastSaved = stats?.lastUpdated;
    final details = [
      if (count == 0) 'હજુ કોસ્ટિંગ નથી' else '$count ડિઝાઇન',
      if (lastSaved != null) timeAgo(lastSaved),
      if (client.city.isNotEmpty) client.city,
    ].join(' · ');
    const corner = Radius.circular(20);
    return Material(
      color: context.colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.vertical(
        top: first ? corner : Radius.zero,
        bottom: last ? corner : Radius.zero,
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            onLongPress: onLongPress,
            contentPadding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
            leading: ClientAvatar(name: client.name, radius: 20),
            title: Text(
              client.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle:
                Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          if (!last) const Divider(indent: 72),
        ],
      ),
    );
  }
}
