import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../core/models/controller_state.dart';

class TCPClient {
  Socket? _socket;
  Timer? _sendTimer;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  bool _isReconnecting = false;

  String _ip = '192.168.1.100';
  int _port = 8080;

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  String get ip => _ip;
  int get port => _port;
  bool get isConnected => _isConnected;

  String get currentStatus => _isConnected ? 'Connected' : 'Disconnected';

  void updateIP(String ip) {
    _ip = ip;
    _restartConnection();
  }

  void updatePort(int port) {
    _port = port;
    _restartConnection();
  }

  void _restartConnection() {
    // If we are active (connected or trying to), restart the process with new settings
    // If we are fully stopped, do nothing (user must call connect())
    if (_isConnected || _isReconnecting) {
      _socket
          ?.destroy(); // Will trigger _handleDisconnection -> _scheduleReconnect
    }
  }

  Future<void> connect() async {
    if (_isConnected) return;
    _stopReconnect();
    await _attemptConnection();
  }

  Future<void> _attemptConnection() async {
    try {
      _safeAddStatus('Connecting to $_ip:$_port...');

      _socket?.destroy();
      _socket = null;

      final socketFuture = Socket.connect(
        _ip,
        _port,
        timeout: const Duration(seconds: 5),
      );

      _socket = await socketFuture;
      _isConnected = true;
      _isReconnecting = false;
      _safeAddStatus('Connected');

      _sendTimer?.cancel();
      _sendTimer = Timer.periodic(
        const Duration(milliseconds: 20),
        (_) => _sendData(),
      );

      _socket!.listen(
        (data) {},
        onError: (error) {
          _safeAddStatus('Socket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          _safeAddStatus('Socket closed by server');
          _handleDisconnection();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _isConnected = false;
      _safeAddStatus('Connection failed: $e');
      _scheduleReconnect();
    }
  }

  ControllerState? _currentState;

  void updateState(ControllerState state) {
    _currentState = state;
  }

  void _safeAddStatus(String status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  bool _isSendingData = false;

  Future<void> _sendData() async {
    if (!_isConnected ||
        _socket == null ||
        _currentState == null ||
        _isSendingData) {
      return;
    }

    _isSendingData = true;
    try {
      final jsonString = jsonEncode(_currentState!.toJson());
      _socket?.write('$jsonString\n');
      await _socket?.flush();
    } catch (e) {
      _handleDisconnection();
    } finally {
      _isSendingData = false;
    }
  }

  void _handleDisconnection() {
    if (!_isConnected && _socket == null) {
      return;
    }

    _isConnected = false;
    _sendTimer?.cancel();
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;

    _safeAddStatus('Disconnected');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isReconnecting) return;
    _isReconnecting = true;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () async {
      // Check if we were stopped during the wait
      if (_isReconnecting) {
        // Reset flag so that if _attemptConnection fails and calls _scheduleReconnect,
        // it won't be blocked by the check at the top of this function.
        _isReconnecting = false;
        await _attemptConnection();
      }
    });
  }

  void _stopReconnect() {
    _isReconnecting = false;
    _reconnectTimer?.cancel();
  }

  void disconnect() {
    _stopReconnect();
    _sendTimer?.cancel();
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
    _safeAddStatus('Disconnected');
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}
