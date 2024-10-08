
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedClientNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void set(String? guid){
    state = guid;
  }
}

final  NotifierProvider<SelectedClientNotifier, String?> selectedClientProvider =
    NotifierProvider<SelectedClientNotifier, String?>(SelectedClientNotifier.new);
