import 'package:costing_master/costings/notifier/costings_notifier.dart';
import 'package:costing_master/model/client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedClientNotifier extends Notifier<Client?> {
  @override
  Client? build() {
    return null;
  }

  void set(Client? client) {
    state = client;
    ref.read(costingsProvider.notifier).refresh();
  }
}

final selectedClientProvider =
    NotifierProvider<SelectedClientNotifier, Client?>(
        SelectedClientNotifier.new);
