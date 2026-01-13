import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../core/models/controller_state.dart';

class TCPClient {
  Socket? _socket;
  Timer? _reconnectTimer;
  Timer? _sendTimer;
  bool _isConnected = false;
  bool _shouldReconnect = true;

  String _ip = '192.168.1.100';
  int _port = 8080;

  Function(String)? onConnectionStatusChanged;
  Function(String)? onError;

  String get ip => _ip;
  int get port => _port;
  bool get isConnected => _isConnected;

  void updateIP(String ip) {
    _ip = ip;
    _disconnect();
  }

  void updatePort(int port) {
    _port = port;
    _disconnect();
  }

  Future<void> connect() async {
    if (_isConnected) return;

    _shouldReconnect = true;
    await _attemptConnection();
  }

  Future<void> _attemptConnection() async {
    try {
      _socket = await Socket.connect(
        _ip,
        _port,
        timeout: const Duration(seconds: 5),
      );
      _isConnected = true;
      onConnectionStatusChanged?.call('Connected');

      // Start sending data at constant rate (50 Hz = 20ms interval)
      _sendTimer?.cancel();
      _sendTimer = Timer.periodic(
        const Duration(milliseconds: 20),
        (_) => _sendData(),
      );

      // Listen for disconnections
      _socket!.listen(
        null,
        onError: (error) {
          _handleDisconnection();
        },
        onDone: () {
          _handleDisconnection();
        },
      );

      _reconnectTimer?.cancel();
    } catch (e) {
      _isConnected = false;
      onConnectionStatusChanged?.call('Connecting...');

      // Retry connection after 2 seconds
      if (_shouldReconnect) {
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(const Duration(seconds: 2), () {
          if (_shouldReconnect && !_isConnected) {
            _attemptConnection();
          }
        });
      }
    }
  }

  ControllerState? _currentState;

  void updateState(ControllerState state) {
    _currentState = state;
  }

  void _sendData() {
    if (!_isConnected || _socket == null || _currentState == null) return;

    try {
      final jsonString = jsonEncode(_currentState!.toJson());

      // Optimized: Pre-encode newline and combine in single add call
      final bytes = utf8.encode('$jsonString\n');
      _socket!.add(bytes);
    } catch (e) {
      onError?.call('Send error: $e');
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _socket?.destroy();
    _socket = null;
    _sendTimer?.cancel();
    onConnectionStatusChanged?.call('Disconnected');

    // Attempt to reconnect
    if (_shouldReconnect) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 2), () {
        if (_shouldReconnect && !_isConnected) {
          _attemptConnection();
        }
      });
    }
  }

  void _disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _sendTimer?.cancel();
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
    onConnectionStatusChanged?.call('Disconnected');
  }

  void disconnect() {
    _disconnect();
  }

  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _sendTimer?.cancel();
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
  }
}
