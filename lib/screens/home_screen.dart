import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/providers/settings_provider.dart';
import 'settings_screen.dart';
import '../core/services/controller_registry.dart';
import '../core/di/service_locator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  Future<void> _initConnection() async {
    // Wait for settings to load from storage
    await ref.read(settingsProvider.notifier).ensureLoaded();

    final settings = ref.read(settingsProvider);
    final tcpClient = ref.read(tcpClientProvider);
    tcpClient.updateIP(settings.ip);
    tcpClient.updatePort(settings.port);
    tcpClient.connect();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    final controllerRegistry = getIt<ControllerRegistry>();
    final controller =
        controllerRegistry.getController(settings.controllerId) ??
        controllerRegistry.getController('touch_drive') ??
        controllerRegistry.getAllControllers().firstOrNull;

    // Safety check: if no controllers are registered, show error
    if (controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error: No controllers registered',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    // Watch connection status using Riverpod
    final connectionStatusAsync = ref.watch(connectionStatusProvider);
    final connectionStatus =
        connectionStatusAsync.valueOrNull ?? 'Disconnected';

    // Show error snackbar if error occurs (optional listener)
    ref.listen(connectionStatusProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection Error: ${next.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Get TCP Client to access updateState
    final tcpClient = ref.read(tcpClientProvider);

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Controller UI
            controller.buildUI(context, (state) {
              tcpClient.updateState(state);
            }),

            // Overlay UI (Connection Status & Settings)
            Positioned(
              top: 16,
              left: 16,
              child: _buildConnectionStatus(connectionStatus),
            ),

            Positioned(top: 16, right: 16, child: _buildSettingsButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(String status) {
    Color statusColor;
    if (status == 'Connected') {
      statusColor = const Color(0xFF00D4AA);
    } else if (status.contains('Connecting')) {
      statusColor = const Color(0xFFFFB84D);
    } else {
      statusColor = const Color(0xFFFF6B6B);
    }

    return Tooltip(
      message: status,
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
                const SettingsScreen(),
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
