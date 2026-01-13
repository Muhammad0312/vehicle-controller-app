import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/controller_registry.dart';
import 'controllers/touch_drive/touch_drive_controller.dart';
import 'controllers/ps4/ps4_controller.dart';
import 'controllers/ps5/ps5_controller.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Controllers
  final registry = ControllerRegistry();
  registry.register(TouchDriveController());
  registry.register(PS4Controller());
  registry.register(PS5Controller());

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
      title: 'Vehicle Controller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
