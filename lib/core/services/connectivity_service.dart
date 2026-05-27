import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ConnectivityService
//
//  Wraps connectivity_plus and exposes a typed online/offline stream.
//
//  Usage:
//    final sub = ConnectivityService.instance.onlineStream.listen((online) { … });
//    final ok  = await ConnectivityService.instance.isOnline;
// ─────────────────────────────────────────────────────────────────────────────

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();

  /// Emits [true] whenever at least one network interface is available,
  /// [false] when all are gone.  Only fires on *changes* — subscribe early.
  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );

  /// One-time snapshot — await this before kicking off a network call.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  isNetworkError
//
//  Returns true when [error] is a connectivity/socket failure.
//  Works even when the original SocketException has been wrapped inside a
//  domain exception (e.g. ProfileApiException("Failed to load: SocketException…")).
// ─────────────────────────────────────────────────────────────────────────────

bool isNetworkError(dynamic error) {
  if (error is SocketException) return true;
  final s = error.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('no address associated') ||
      s.contains('network error') ||
      s.contains('connection failed');
}