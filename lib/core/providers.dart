import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tcp_client.dart';
import 'di/service_locator.dart';

// Access the singleton from GetIt
final tcpClientProvider = Provider<TCPClient>((ref) {
  return getIt<TCPClient>();
});

// Expose status stream with immediate current value
final connectionStatusProvider = StreamProvider<String>((ref) async* {
  final client = ref.watch(tcpClientProvider);
  // Yield current status immediately so UI is not waiting
  yield client.currentStatus;
  // Then yield all stream events
  yield* client.statusStream;
});
