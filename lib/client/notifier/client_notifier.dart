import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/client/repository/client_repository.dart';
import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/model/client.dart';
import 'package:costing_master/sync/sync_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuplicateClientException implements Exception {
  final String name;
  const DuplicateClientException(this.name);
}

class ClientNotifier extends AsyncNotifier<List<Client>> {
  ClientRepository get _repository => ref.read(clientRepositoryProvider);

  @override
  Future<List<Client>> build() async {
    final clients = await _repository.getClients();
    return clients..sort(_byName);
  }

  /// Adds a client, or updates [existing] when given. Throws
  /// [DuplicateClientException] if another client already has the name.
  Future<Client> save({
    required String name,
    String phone = '',
    String city = '',
    Client? existing,
  }) async {
    final trimmed = name.trim();
    final current = state.value ?? const <Client>[];
    if (current.any((c) =>
        c.guid != existing?.guid &&
        c.name.toLowerCase() == trimmed.toLowerCase())) {
      throw DuplicateClientException(trimmed);
    }
    final client = existing == null
        // Guests have no uid yet; it is filled in when the client is backed up.
        ? Client(
            name: trimmed,
            phone: phone.trim(),
            city: city.trim(),
            createdBy: ref.read(authProvider).value?.uid ?? '')
        : existing.copyWith(
            name: trimmed,
            phone: phone.trim(),
            city: city.trim(),
            updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _repository.saveClient(client);
    state = AsyncData([
      for (final c in current)
        if (c.guid != client.guid) c,
      client,
    ]..sort(_byName));
    ref.read(syncProvider.notifier).syncSoon();
    return client;
  }

  /// Deletes [client] and its costings; [restore] brings them back.
  Future<void> delete(Client client) async {
    await _repository.delete(client.guid);
    state = AsyncData([
      for (final c in state.value ?? const <Client>[])
        if (c.guid != client.guid) c,
    ]);
    ref.invalidate(costingsProvider(client.guid));
    ref.read(syncProvider.notifier).syncSoon();
  }

  Future<void> restore(Client client) async {
    await _repository.restore(client.guid);
    ref.invalidateSelf();
    ref.invalidate(costingsProvider(client.guid));
    ref.read(syncProvider.notifier).syncSoon();
  }

  static int _byName(Client a, Client b) =>
      a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

final clientsProvider =
    AsyncNotifierProvider<ClientNotifier, List<Client>>(ClientNotifier.new);
