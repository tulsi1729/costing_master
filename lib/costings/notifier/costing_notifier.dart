import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> updateCosting(Costing costing) async {
  try {
    final costingData = costing.toMap();
    
    await FirebaseFirestore.instance
        .collection('costings')
        .doc(costing.guid)
        .update(costingData);
        
    print('Costing updated successfully: ${costing.guid}');
  } catch (e) {
    print('Error updating costing: $e');
    // If document doesn't exist, create it
    if (e.toString().contains('NOT_FOUND')) {
      await FirebaseFirestore.instance
          .collection('costings')
          .doc(costing.guid)
          .set(costing.toMap());
      print('Costing created as it did not exist: ${costing.guid}');
    } else {
      rethrow;
    }
  }
}
}

final costingProvider =
    NotifierProvider<CostingNotifier, void>(CostingNotifier.new);
