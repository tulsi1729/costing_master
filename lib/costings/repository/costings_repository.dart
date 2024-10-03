import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:costing_master/constant/firebase_constants.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/provider/firebase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final costingsRepositoryProvider = Provider((ref) {
  return CostingsRepository(firestore: ref.watch(firestoreProvider));
});

class CostingsRepository {
  final FirebaseFirestore _firestore;

  CostingsRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<bool> createCostings(Costing costing) async {
    try {
      await _costings.doc(costing.createdBy).get();
      await _costings.doc(costing.createdBy).set(costing.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Costing>> getUserCostings(String createdByUid) async {
    final Stream<List<Costing>> costingsStream = _costings
        .where('createdBy', isEqualTo: createdByUid)
        .snapshots()
        .map((event) {
      List<Costing> costings = [];
      for (final doc in event.docs) {
        costings.add(
          Costing.fromMap(doc.data() as Map<String, dynamic>),
        );
      }
      return costings;
    });

    List<Costing> costings = await costingsStream.first;

    return costings;
  }

  Future<bool> createCosting(Costing costing) async {
    try {
      await _costings.doc(costing.createdBy).get();
      await _costings.doc(costing.createdBy).set(costing.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Costing>> getUserCosting(String createdByUid) async {
    final Stream<List<Costing>> costingStream = _costings
        .where('createdBy', isEqualTo: createdByUid)
        .snapshots()
        .map((event) {
      List<Costing> costing = [];
      for (final doc in event.docs) {
        costing.add(
          Costing.fromMap(doc.data() as Map<String, dynamic>),
        );
      }
      return costing;
    });

    List<Costing> costing = await costingStream.first;

    return costing;
  }

  CollectionReference get _costings =>
      _firestore.collection(FirebaseConstants.costingsColletion);
}
