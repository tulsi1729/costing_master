import 'dart:async';

import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/costing/repository/costing_repository.dart';
import 'package:costing_master/model/costing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CostingNotifier extends AsyncNotifier<List<Costing>> {
  late final CostingRepository _costingRepository;

  @override
  FutureOr<List<Costing>> build() async{
    _costingRepository = ref.read(costingRepositoryProvider);
    state = const AsyncLoading();
    return await getCosting();
  }

  Future<bool> createCosting(Costing costing) async {
    final bool isCostingsCreated = await _costingRepository.createCosting(costing);
    return isCostingsCreated;
  }

  Future<List<Costing>> getCosting() async {
    final loggedInUserUid = (await ref.read(authProvider.future))!.uid;
    final List<Costing> clients =
        await _costingRepository.getUserCostings(loggedInUserUid);

    return clients;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    List<Costing> costings = await getCosting();
    state = AsyncValue.data(costings);
  }


}

final clientsProvider =
    AsyncNotifierProvider<CostingNotifier, List<Costing>>(CostingNotifier.new);
