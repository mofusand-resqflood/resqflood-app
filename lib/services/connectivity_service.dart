import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Checks whether the device has working internet access.
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();

    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Emits the initial connection status and listens for changes.
  Stream<bool> get connectionStream async* {
    yield await checkConnection();

    yield* _connectivity.onConnectivityChanged
        .asyncMap((_) => checkConnection())
        .distinct();
  }
}
