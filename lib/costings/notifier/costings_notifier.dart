import 'dart:async';

import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/costings/notifier/selected_client_notifier.dart';
import 'package:costing_master/costings/repository/costings_repository.dart';
import 'package:costing_master/model/costing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CostingsNotifier extends AsyncNotifier<List<Costing>> {
  late final CostingsRepository _costingsRepository;

  @override
  FutureOr<List<Costing>> build() async {
    _costingsRepository = ref.read(costingsRepositoryProvider);
    state = const AsyncLoading();
    return await getCostings();
  }

  Future<bool> createCostings(Costing costing) async {
    final bool isCostingCreated =
        await _costingsRepository.createCosting(costing);
    return isCostingCreated;
  }

  Future<List<Costing>> getCostings() async {
    final loggedInUserUid = (await ref.read(authProvider.future))!.uid;
    final String selectedClientGuid = ref.read(selectedClientProvider)!.guid;
    final List<Costing> costings = await _costingsRepository.getUserCostings(
        loggedInUserUid, selectedClientGuid);

    return costings;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    List<Costing> costings = await getCostings();
    state = AsyncValue.data(costings);
  }
  
}

final costingsProvider = AsyncNotifierProvider<CostingsNotifier, List<Costing>>(
    CostingsNotifier.new);
