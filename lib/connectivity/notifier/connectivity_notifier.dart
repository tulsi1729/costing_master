import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends StreamNotifier<bool> {
  final Connectivity _connectivity = Connectivity();

  @override
  Stream<bool> build() async* {
    // Check initial connectivity
    final initialResult = await _connectivity.checkConnectivity();
    yield _hasConnection(initialResult);

    // Listen to connectivity changes
    yield* _connectivity.onConnectivityChanged.map((result) {
      return _hasConnection(result);
    });
  }

  bool _hasConnection(List<ConnectivityResult> result) {
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }
}

final connectivityProvider =
    StreamNotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);

