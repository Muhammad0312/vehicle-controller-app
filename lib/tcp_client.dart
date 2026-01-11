import 'dart:async';
import 'dart:io';
import 'dart:convert';

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
  
  // Control states
  double _steeringX = 0.0;
  double _steeringY = 0.0;
  double _gas = 0.0;
  double _brake = 0.0;
  String _gear = 'P'; // P, D, N, R
  bool _autoMode = false;
  bool _leftBlinker = false;
  bool _rightBlinker = false;
  
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
  
  void updateSteering(double x, double y) {
    _steeringX = x;
    _steeringY = y;
  }
  
  void updateGas(double value) {
    _gas = value.clamp(0.0, 1.0);
  }
  
  void updateBrake(double value) {
    _brake = value.clamp(0.0, 1.0);
  }
  
  void updateGear(String gear) {
    _gear = gear;
  }
  
  void updateAutoMode(bool enabled) {
    _autoMode = enabled;
  }
  
  void updateLeftBlinker(bool enabled) {
    _leftBlinker = enabled;
  }
  
  void updateRightBlinker(bool enabled) {
    _rightBlinker = enabled;
  }
  
  Future<void> connect() async {
    if (_isConnected) return;
    
    _shouldReconnect = true;
    await _attemptConnection();
  }
  
  Future<void> _attemptConnection() async {
    try {
      _socket = await Socket.connect(_ip, _port, timeout: const Duration(seconds: 5));
      _isConnected = true;
      onConnectionStatusChanged?.call('Connected');
      
      // Start sending data at constant rate (50 Hz = 20ms interval)
      _sendTimer?.cancel();
      _sendTimer = Timer.periodic(const Duration(milliseconds: 20), (_) => _sendData());
      
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
      // Don't call onError for connection failures - status indicator shows the state
      // Only log connection errors silently
      
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
  
  void _sendData() {
    if (!_isConnected || _socket == null) return;
    
    try {
      // Optimized: Build JSON map directly without intermediate variables
      final jsonString = jsonEncode({
        'steering': {'x': _steeringX, 'y': _steeringY},
        'gas': _gas,
        'brake': _brake,
        'gear': _gear,
        'autoMode': _autoMode,
        'leftBlinker': _leftBlinker,
        'rightBlinker': _rightBlinker,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
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
