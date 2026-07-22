import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits true when any non-none connectivity is available.
final connectivityOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  });
});

final connectivityInitialProvider = FutureProvider<bool>((ref) async {
  final results = await Connectivity().checkConnectivity();
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
});
