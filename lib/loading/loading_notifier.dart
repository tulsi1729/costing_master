import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void set(bool isLoading) {
    state = isLoading;
  }
}

final loadingProvider =
    NotifierProvider<LoadingNotifier, bool>(LoadingNotifier.new);
