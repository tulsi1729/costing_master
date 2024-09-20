import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/client/repository/client_repository.dart';
import 'package:costing_master/model/client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientNotifier extends AsyncNotifier<List<Client>> {
  late final ClientRepository _clientRepository;

  @override
  Future<List<Client>> build() async {
    _clientRepository = ref.read(clientRepositoryProvider);
    state = const AsyncLoading();
    return await getClients();
  }

  Future<bool> createClient(Client client) async {
    final bool isClientCreated = await _clientRepository.createClient(client);
    return isClientCreated;
  }

  Future<List<Client>> getClients() async {
    final loggedInUserUid = (await ref.read(authProvider.future))!.uid;
    final List<Client> clients =
        await _clientRepository.getUserClients(loggedInUserUid);

    return clients;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    List<Client> clients = await getClients();
    state = AsyncValue.data(clients);
  }
}

final clientsProvider =
    AsyncNotifierProvider<ClientNotifier, List<Client>>(ClientNotifier.new);
