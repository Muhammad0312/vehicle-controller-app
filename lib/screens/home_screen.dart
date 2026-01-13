import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tcp_client.dart';
import 'settings_screen.dart';
import '../core/services/controller_registry.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TCPClient _tcpClient;
  String _connectionStatus = 'Disconnected';
  String _currentControllerId = 'touch_drive';

  @override
  void initState() {
    super.initState();
    _tcpClient = TCPClient();
    _tcpClient.onConnectionStatusChanged = (status) {
      if (mounted) {
        setState(() {
          _connectionStatus = status;
        });
      }
    };
    _tcpClient.onError = (error) {
      if (mounted && !error.toLowerCase().contains('connection')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    };

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('tcp_ip') ?? '192.168.1.100';
    final port = prefs.getInt('tcp_port') ?? 8080;
    final controllerId = prefs.getString('controller_id') ?? 'touch_drive';

    if (mounted) {
      setState(() {
        _currentControllerId = controllerId;
      });
      _tcpClient.updateIP(ip);
      _tcpClient.updatePort(port);
      _tcpClient.connect();
    }
  }

  void _onSettingsChanged(String ip, int port, String controllerId) {
    setState(() {
      _currentControllerId = controllerId;
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
    final controller =
        ControllerRegistry().getController(_currentControllerId) ??
        ControllerRegistry().getController('touch_drive')!;

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Controller UI
            controller.buildUI(context, (state) {
              _tcpClient.updateState(state);
            }),

            // Overlay UI (Connection Status & Settings)
            Positioned(top: 16, left: 16, child: _buildConnectionStatus()),

            Positioned(top: 16, right: 16, child: _buildSettingsButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    Color statusColor;
    if (_connectionStatus == 'Connected') {
      statusColor = const Color(0xFF00D4AA);
    } else if (_connectionStatus.contains('Connecting')) {
      statusColor = const Color(0xFFFFB84D);
    } else {
      statusColor = const Color(0xFFFF6B6B);
    }

    return Tooltip(
      message: _connectionStatus,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      icon: const Icon(Icons.settings, color: Colors.white54),
      tooltip: 'Settings',
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                SettingsScreen(
                  currentIP: _tcpClient.ip,
                  currentPort: _tcpClient.port,
                  currentControllerId: _currentControllerId,
                  onSettingsChanged: _onSettingsChanged,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const curve = Curves.easeOutQuint;
                  var tween = Tween(
                    begin: 0.9,
                    end: 1.0,
                  ).chain(CurveTween(curve: curve));
                  var fadeTween = Tween(
                    begin: 0.0,
                    end: 1.0,
                  ).chain(CurveTween(curve: curve));

                  return FadeTransition(
                    opacity: animation.drive(fadeTween),
                    child: ScaleTransition(
                      scale: animation.drive(tween),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            barrierColor: Colors.black.withValues(alpha: 0.8),
            maintainState: true,
            fullscreenDialog: true,
          ),
        );
      },
    );
  }
}
