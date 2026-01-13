import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tcp_client.dart';
import 'di/service_locator.dart';

// Access the singleton from GetIt
final tcpClientProvider = Provider<TCPClient>((ref) {
  return getIt<TCPClient>();
});

// Expose status stream
final connectionStatusProvider = StreamProvider<String>((ref) {
  final client = ref.watch(tcpClientProvider);
  return client.statusStream;
});
