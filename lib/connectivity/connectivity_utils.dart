import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:costing_master/connectivity/notifier/connectivity_notifier.dart';

/// Utility class for checking connectivity status
class ConnectivityUtils {
  /// Check if device is currently connected to the internet
  static Future<bool> isConnected() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }

  /// Get current connectivity status from the provider
  static bool? getCurrentStatus(WidgetRef ref) {
    final connectivityState = ref.read(connectivityProvider);
    return connectivityState.value;
  }

  /// Check if connected, show error if not
  /// Returns true if connected, false otherwise
  static Future<bool> requireConnection(WidgetRef ref) async {
    final isConnected = await ConnectivityUtils.isConnected();
    return isConnected;
  }
}

