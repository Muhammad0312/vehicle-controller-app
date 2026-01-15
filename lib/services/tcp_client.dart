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
  int _reconnectAttempts = 0;
  static const int _baseReconnectDelay = 2; // seconds
  static const int _maxReconnectDelay = 30; // cap at 30 seconds

  String _ip = '192.168.1.100';
  int _port = 8080;

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  String get ip => _ip;
  int get port => _port;
  bool get isConnected => _isConnected;

  // Current status getter
  String get currentStatus => _isConnected ? 'Connected' : 'Disconnected';

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
    _reconnectAttempts = 0; // Reset attempts on manual connect
    await _attemptConnection();
  }

  Future<void> _attemptConnection() async {
    try {
      _safeAddStatus('Connecting...');
      _socket = await Socket.connect(
        _ip,
        _port,
        timeout: const Duration(seconds: 5),
      );
      _isConnected = true;
      _reconnectAttempts = 0; // Reset counter on successful connection
      _safeAddStatus('Connected');

      // Start sending data at constant rate (50 Hz = 20ms interval)
      _sendTimer?.cancel();
      _sendTimer = Timer.periodic(
        const Duration(milliseconds: 20),
        (_) => _sendData(),
      );

      // Listen for disconnections
      _socket!
          .listen(
            null,
            onError: (error) {
              _handleDisconnection();
            },
            onDone: () {
              _handleDisconnection();
            },
            cancelOnError: false, // Continue listening even after errors
          )
          .onError((error, stackTrace) {
            // Catch any unhandled errors from the stream
            _handleDisconnection();
          });

      _reconnectTimer?.cancel();
    } catch (e) {
      _isConnected = false;
      _reconnectAttempts++;

      // Calculate exponential backoff delay, capped at max
      final exponentialDelay =
          _baseReconnectDelay * (1 << (_reconnectAttempts - 1).clamp(0, 5));
      final delay = exponentialDelay.clamp(
        _baseReconnectDelay,
        _maxReconnectDelay,
      );
      _safeAddStatus('Reconnecting in ${delay}s (attempt $_reconnectAttempts)');

      // Retry connection with exponential backoff (infinite retries)
      if (_shouldReconnect) {
        _reconnectTimer?.cancel();
        _reconnectTimer = Timer(Duration(seconds: delay), () {
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

  void _safeAddStatus(String status) {
    try {
      if (!_statusController.isClosed) {
        _statusController.add(status);
      }
    } catch (e) {
      // Ignore errors when adding to closed stream
    }
  }

  void _sendData() {
    if (!_isConnected || _socket == null || _currentState == null) return;

    try {
      final jsonString = jsonEncode(_currentState!.toJson());

      // Optimized: Pre-encode newline and combine in single add call
      final bytes = utf8.encode('$jsonString\n');
      _socket?.add(bytes);
    } on SocketException catch (e) {
      // Socket closed or network error - handle gracefully
      _isConnected = false;
      _safeAddStatus('Connection lost: ${e.message}');
      _handleDisconnection();
    } catch (e) {
      // Any other error during send
      _isConnected = false;
      _safeAddStatus('Send error: $e');
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    try {
      _socket?.destroy();
    } catch (e) {
      // Ignore errors during socket destruction
    }
    _socket = null;
    _sendTimer?.cancel();
    _safeAddStatus('Disconnected');

    // Attempt to reconnect with exponential backoff (infinite retries)
    if (_shouldReconnect) {
      _reconnectAttempts++;

      // Calculate exponential backoff delay, capped at max
      final exponentialDelay =
          _baseReconnectDelay * (1 << (_reconnectAttempts - 1).clamp(0, 5));
      final delay = exponentialDelay.clamp(
        _baseReconnectDelay,
        _maxReconnectDelay,
      );

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(Duration(seconds: delay), () {
        if (_shouldReconnect && !_isConnected) {
          _attemptConnection();
        }
      });
    }
  }

  void _disconnect() {
    _shouldReconnect = false;
    _reconnectAttempts = 0; // Reset for next connection attempt
    _reconnectTimer?.cancel();
    _sendTimer?.cancel();
    try {
      _socket?.destroy();
    } catch (e) {
      // Ignore errors during socket destruction
    }
    _socket = null;
    _isConnected = false;
    _safeAddStatus('Disconnected');
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
    _statusController.close();
  }
}
