import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:costing_master/constant/firebase_constants.dart';
import 'package:costing_master/model/costing.dart';
import 'package:costing_master/provider/firebase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final costingRepositoryProvider = Provider((ref) {
  return CostingRepository(firestore: ref.watch(firestoreProvider));
});

class CostingRepository {
  final FirebaseFirestore _firestore;

  CostingRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<bool> createCosting(Costing costing) async {
    try {
      await _costings.doc(costing.createdBy).get();
      await _costings.doc(costing.createdBy).set(costing.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }


  Future<List<Costing>> getUserCostings(String createdByUid) async {
    final Stream<List<Costing>> clientsStream = _costings
        .where('createdBy', isEqualTo: createdByUid)
        .snapshots()
        .map((event) {
      List<Costing> clients = [];
      for (var doc in event.docs) {
        clients.add(
          Costing.fromMap(doc.data() as Map<String, dynamic>),
        );
      }
      return clients;
    });

    List<Costing> clients = await clientsStream.first;

    return clients;
  }

  CollectionReference get _costings =>
      _firestore.collection(FirebaseConstants.costingsColletion);
}
