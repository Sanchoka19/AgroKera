import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_client.dart';

/// Network status representation for AgroKera
enum NetworkStatus {
  online,
  offline,
}

/// Modular service responsible exclusively for observing and reporting network connectivity.
class NetworkConnectivityService {
  final Connectivity _connectivity;
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkStatus _lastKnownStatus = NetworkStatus.online;

  NetworkConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    if (!isFlutterTestEnv) {
      _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    }
  }

  NetworkStatus get lastKnownStatus => _lastKnownStatus;
  Stream<NetworkStatus> get onStatusChanged => _statusController.stream;

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
    final newStatus = isConnected ? NetworkStatus.online : NetworkStatus.offline;
    if (newStatus != _lastKnownStatus) {
      _lastKnownStatus = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// Manually checks real-time connectivity status
  Future<NetworkStatus> checkConnectivity() async {
    if (isFlutterTestEnv) {
      return _lastKnownStatus;
    }
    try {
      final results = await _connectivity.checkConnectivity();
      final isConnected = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet,
      );
      _lastKnownStatus = isConnected ? NetworkStatus.online : NetworkStatus.offline;
      return _lastKnownStatus;
    } catch (_) {
      return NetworkStatus.online;
    }
  }

  /// Manually force a status (useful for unit/widget tests and demo offline toggle)
  void setStatusForTesting(NetworkStatus status) {
    _lastKnownStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}

/// Riverpod provider for NetworkConnectivityService
final connectivityServiceProvider = Provider<NetworkConnectivityService>((ref) {
  final service = NetworkConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// Reactive stream provider for real-time network status changes
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChanged;
});

/// Boolean provider indicating whether the device is currently online
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(networkStatusProvider).value ??
      ref.watch(connectivityServiceProvider).lastKnownStatus;
  return status == NetworkStatus.online;
});
