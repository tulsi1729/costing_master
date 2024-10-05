import 'dart:async';

import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/costings/repository/costings_repository.dart';
import 'package:costing_master/model/costing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CostingNotifier extends AsyncNotifier<List<Costing>> {
  late final CostingsRepository _costingsRepository;

  @override
  FutureOr<List<Costing>> build() async {
    _costingsRepository = ref.read(costingsRepositoryProvider);
    state = const AsyncLoading();
    return await getCosting();
  }

  Future<bool> createCosting(Costing costing) async {
    final bool isCostingCreated =
        await _costingsRepository.createCosting(costing);
    return isCostingCreated;
  }

  Future<List<Costing>> getCosting() async {
    final loggedInUserUid = (await ref.read(authProvider.future))!.uid;
    final List<Costing> costing =
        await _costingsRepository.getUserCostings(loggedInUserUid);

    return costing;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    List<Costing> costing = await getCosting();
    state = AsyncValue.data(costing);
  }
}

final costingProvider =
    AsyncNotifierProvider<CostingNotifier, List<Costing>>(CostingNotifier.new);
