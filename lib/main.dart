import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tcp_client.dart';
import 'joystick_widget.dart';
import 'gas_brake_widget.dart';
import 'settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force landscape orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Hide system UI (battery, WiFi bar)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'covolv controller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ControlScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late TCPClient _tcpClient;
  String _connectionStatus = 'Disconnected';
  String _ip = '192.168.1.100';
  int _port = 8080;
  String _gear = 'P';
  bool _autoMode = false;
  bool _leftBlinker = false;
  bool _rightBlinker = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _tcpClient = TCPClient();
    _tcpClient.onConnectionStatusChanged = (status) {
      setState(() {
        _connectionStatus = status;
      });
    };
    _tcpClient.onError = (error) {
      // Don't show connection errors repeatedly - the status indicator already shows connection state
      // Only show send errors or other non-connection errors
      if (!error.toLowerCase().contains('connection failed') && 
          !error.toLowerCase().contains('connection error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    };
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ip = prefs.getString('tcp_ip') ?? '192.168.1.100';
      _port = prefs.getInt('tcp_port') ?? 8080;
    });
    _tcpClient.updateIP(_ip);
    _tcpClient.updatePort(_port);
    _tcpClient.connect();
  }

  void _onSettingsChanged(String ip, int port) {
    setState(() {
      _ip = ip;
      _port = port;
    });
    _tcpClient.updateIP(ip);
    _tcpClient.updatePort(port);
    _tcpClient.connect();
  }

  @override
  void dispose() {
    _tcpClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27), // Deep navy
              Color(0xFF1A1F3A), // Dark blue-gray
              Color(0xFF0F1419), // Almost black
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final pedalHeight = (screenHeight * 0.6).clamp(200.0, 400.0);
            
            return Row(
              children: [
                // Left side - Gas and Brake
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: pedalHeight,
                            maxWidth: 200,
                          ),
                          child: GasBrakeWidget(
                            onChanged: (gas, brake) {
                              _tcpClient.updateGas(gas);
                              _tcpClient.updateBrake(brake);
                            },
                            width: 80,
                            height: pedalHeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
                // Middle - Control buttons
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Connection status
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _connectionStatus == 'Connected'
                                  ? [Color(0xFF00D4AA), Color(0xFF00B894)]
                                  : _connectionStatus == 'Connecting...'
                                      ? [Color(0xFFFFB84D), Color(0xFFFF9500)]
                                      : [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: (_connectionStatus == 'Connected'
                                        ? Color(0xFF00D4AA)
                                        : _connectionStatus == 'Connecting...'
                                            ? Color(0xFFFFB84D)
                                            : Color(0xFFFF6B6B))
                                    .withAlpha((0.4 * 255).round()),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _connectionStatus,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Gear selection
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.05 * 255).round()),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withAlpha((0.1 * 255).round()),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildGearButton('P', 'Park'),
                                  SizedBox(width: 6),
                                  _buildGearButton('R', 'Reverse'),
                                  SizedBox(width: 6),
                                  _buildGearButton('N', 'Neutral'),
                                  SizedBox(width: 6),
                                  _buildGearButton('D', 'Drive'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Auto mode
                        Container(
                          decoration: BoxDecoration(
                            gradient: _autoMode
                                ? LinearGradient(
                                    colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
                                  )
                                : null,
                            color: _autoMode ? null : Colors.white.withAlpha((0.08 * 255).round()),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _autoMode
                                  ? Colors.transparent
                                  : Colors.white.withAlpha((0.15 * 255).round()),
                              width: 1.5,
                            ),
                            boxShadow: _autoMode
                                ? [
                                    BoxShadow(
                                      color: Color(0xFF00D4AA).withAlpha((0.3 * 255).round()),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _autoMode = !_autoMode;
                                });
                                _tcpClient.updateAutoMode(_autoMode);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_mode,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'AUTO MODE',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Blinkers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBlinkerButton(true),
                            SizedBox(width: 16),
                            _buildBlinkerButton(false),
                          ],
                        ),
                        
                        // Settings button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.08 * 255).round()),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha((0.15 * 255).round()),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => SettingsScreen(
                                      currentIP: _ip,
                                      currentPort: _port,
                                      onSettingsChanged: _onSettingsChanged,
                                    ),
                                    transitionDuration: Duration(milliseconds: 400),
                                    reverseTransitionDuration: Duration(milliseconds: 300),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      const curve = Curves.easeOutCubic;

                                      // Fade animation
                                      var fadeAnimation = Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).chain(
                                        CurveTween(curve: curve),
                                      );

                                      // Scale animation
                                      var scaleAnimation = Tween<double>(
                                        begin: 0.95,
                                        end: 1.0,
                                      ).chain(
                                        CurveTween(curve: curve),
                                      );

                                      // Slide animation (subtle)
                                      var slideAnimation = Tween<Offset>(
                                        begin: Offset(0.0, 0.02),
                                        end: Offset.zero,
                                      ).chain(
                                        CurveTween(curve: curve),
                                      );

                                      return FadeTransition(
                                        opacity: fadeAnimation.animate(animation),
                                        child: ScaleTransition(
                                          scale: scaleAnimation.animate(animation),
                                          child: SlideTransition(
                                            position: slideAnimation.animate(animation),
                                            child: child,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              customBorder: CircleBorder(),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white.withAlpha((0.9 * 255).round()),
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Right side - Joystick
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(left: 0, top: 16, right: 16, bottom: 16), // No left padding to move it left
                    child: Align(
                      alignment: Alignment(-1.0, 0.0), // Maximum left position
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final joystickSize = constraints.maxHeight.clamp(150.0, 250.0);
                            return JoystickWidget(
                              onChanged: (x, y) {
                                // Clamp to -1.0 to 1.0 range (joystick already outputs full range)
                                final clampedX = x.clamp(-1.0, 1.0);
                                _tcpClient.updateSteering(clampedX, y);
                              },
                              size: joystickSize,
                            );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGearButton(String gear, String label) {
    final isSelected = _gear == gear;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _gear = gear;
          });
          _tcpClient.updateGear(gear);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  )
                : null,
            color: isSelected ? null : Colors.white.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.white.withAlpha((0.15 * 255).round()),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Color(0xFF6366F1).withAlpha((0.4 * 255).round()),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gear,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withAlpha((0.7 * 255).round()),
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlinkerButton(bool isLeft) {
    final isActive = isLeft ? _leftBlinker : _rightBlinker;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (isLeft) {
              // If left is already active, turn it off. Otherwise, turn it on and turn right off
              _leftBlinker = !_leftBlinker;
              if (_leftBlinker) {
                _rightBlinker = false;
                _tcpClient.updateRightBlinker(false);
              }
              _tcpClient.updateLeftBlinker(_leftBlinker);
            } else {
              // If right is already active, turn it off. Otherwise, turn it on and turn left off
              _rightBlinker = !_rightBlinker;
              if (_rightBlinker) {
                _leftBlinker = false;
                _tcpClient.updateLeftBlinker(false);
              }
              _tcpClient.updateRightBlinker(_rightBlinker);
            }
          });
        },
        customBorder: CircleBorder(),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB84D), Color(0xFFFF9500)],
                  )
                : null,
            color: isActive ? null : Colors.white.withAlpha((0.08 * 255).round()),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : Colors.white.withAlpha((0.15 * 255).round()),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Color(0xFFFFB84D).withAlpha((0.4 * 255).round()),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isLeft ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
