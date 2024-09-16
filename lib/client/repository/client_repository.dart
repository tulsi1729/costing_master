import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:costing_master/constant/firebase_constant.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/provider/firebase_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientRepositoryProvider = Provider((ref) {
  return ClientRepository(firestore: ref.watch(firestoreProvider));
});

class ClientRepository {
  final FirebaseFirestore _firestore;

  ClientRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  Future<bool> createClient(Client client) async {
    try {
      final clientDoc = await _clients.doc(client.uid).get();
      if (clientDoc.exists) {
        throw 'Client with the same name already exists!';
      }
      await _clients.doc(client.uid).set(client.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Client>> getUserClients(String createdByUid) async {
    final Stream<List<Client>> clientsStream = _clients
        .where('createdBy', isEqualTo: createdByUid)
        .snapshots()
        .map((event) {
      List<Client> clients = [];
      for (var doc in event.docs) {
        clients.add(
          Client.fromMap(doc.data() as Map<String, dynamic>),
        );
      }
      log('clients repo $clients');
      return clients;
    });

    List<Client> clients = await clientsStream.first;

    log(clients.toString(), name: "repo");
    return clients;
  }

  CollectionReference get _clients =>
      _firestore.collection(FirebaseConstants.clientCollection);
}
