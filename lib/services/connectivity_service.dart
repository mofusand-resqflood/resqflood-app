import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Checks the available network connection.
  /// Internet reachability is confirmed by the actual Supabase request.
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();

    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  /// Emits the initial connection status and listens for changes.
  Stream<bool> get connectionStream async* {
    yield await checkConnection();

    yield* _connectivity.onConnectivityChanged
        .map(
          (results) =>
              results.isNotEmpty && !results.contains(ConnectivityResult.none),
        )
        .distinct();
  }
}
