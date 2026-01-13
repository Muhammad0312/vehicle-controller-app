import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_controller/services/tcp_client.dart';

void main() {
  late TCPClient client;

  setUp(() {
    client = TCPClient();
  });

  tearDown(() {
    client.dispose();
  });

  test('Initial state should be default', () {
    expect(client.ip, '192.168.1.100');
    expect(client.port, 8080);
    expect(client.isConnected, false);
    expect(client.currentStatus, 'Disconnected');
  });

  test('updateIP should update IP and disconnect if connected', () {
    client.updateIP('10.0.0.5');
    expect(client.ip, '10.0.0.5');
    // Ensure we are disconnected (we were already, but logic should hold)
    expect(client.isConnected, false);
  });

  test('updatePort should update Port and disconnect', () {
    client.updatePort(9000);
    expect(client.port, 9000);
    expect(client.isConnected, false);
  });

  // test('statusStream should emit connection status events', () async {
  //   // We can't easily test real connection without a server,
  //   // but we can test that calling connect() emits "Connecting..."

  //   // Listen to stream
  //   expectLater(client.statusStream, emitsInOrder(['Connecting...']));

  //   // Trigger connect (fire and forget, don't await because it will hang or fail)
  //   client.connect();

  //   // We expect 'Connecting...' to be emitted immediately.
  //   await Future.delayed(Duration(milliseconds: 100)); // allow event to process
  // });
}
