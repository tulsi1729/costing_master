import 'dart:async';

import 'package:costing_master/costings/repository/costings_repository.dart';
import 'package:costing_master/model/costing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CostingNotifier extends Notifier {
  late final CostingsRepository _costingsRepository;

  @override
  FutureOr build() async {
    _costingsRepository = ref.read(costingsRepositoryProvider);
  }

  Future<bool> createCosting(Costing costing) async {
    final bool isCostingCreated =
        await _costingsRepository.createCosting(costing);
    return isCostingCreated;
  }
}

final costingProvider =
    NotifierProvider<CostingNotifier, void>(CostingNotifier.new);
