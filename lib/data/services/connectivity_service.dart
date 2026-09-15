import 'package:connectivity_plus/connectivity_plus.dart';

/// Radio state as a plain online/offline stream.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  Future<bool> isOnline() async => _isOnline(await _connectivity.checkConnectivity());

  Stream<bool> get changes => _connectivity.onConnectivityChanged.map(_isOnline).distinct();
}
