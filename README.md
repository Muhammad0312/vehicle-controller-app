# Vehicle Controller App

A professional, modular Flutter application for remote vehicle control via TCP. Designed for robotics and autonomous vehicle projects, it features a scalable plugin-based architecture, allowing developers to easily add custom controller layouts.

## Features
[![Download Latest](https://img.shields.io/github/v/release/yourusername/vehicle_controller_app?label=Download%20APK&style=for-the-badge&logo=android)](https://github.com/yourusername/vehicle_controller_app/releases/latest)

### 📥 Download & Install
1. Click the **Download** button above.
2. Download the `app-release.apk` file from the latest release.
3. Open the file on your Android device and confirm installation.

### 🎮 Multiple Controller Layouts

### 🎮 Multiple Controller Layouts
- **TouchDrive (Default)**:
  - **Steering**: Professional 1-axis joystick (Left side).
  - **Pedals**: Independent Gas & Brake sliders (Right side).
  - **Controls**: Gear selection (P, R, N, D), Blinkers, and Auto-Mode toggle.
- **PS4 Controller**:
  - Full DualShock 4 layout simulation.
  - **Dual Sticks**: 2-axis control for advanced maneuvering.
  - **Triggers**: "Pedal Style" L2/R2 triggers with absolute position sensing.
  - **Technical Aesthetic**: Cyberpunk/Automotive inspired design with Cyan accents.
- **PS5 Controller**:
  - DualSense layout simulation.
  - **Visuals**: Clean, modern aesthetic with Blue accents.
  - **Haptics**: Visual feedback for all button presses.

### ⚙️ Advanced Settings
- **Network Config**: Configure Target IP and Port (Default: `192.168.1.100:8080`).
- **Layout Switching**: Hot-swap between TouchDrive, PS4, and PS5 layouts instantly.
- **Persistence**: Settings are saved automatically across sessions.

### 🛠 Technical Highlights
- **Modular Architecture**: Screens, Services, and Controllers are strictly separated.
- **Real-Time TCP**: 50Hz data transmission rate (20ms latency).
- **Vulkan/Skia Support**: Optimized for broad Android device compatibility (Impeller disabled for Adreno stability).
- **Immersive Mode**: Full-screen landscape experience.

---

## Architecture

The project follows a clean, modular structure:

```
lib/
├── main.dart                  # Entry point & App Initialization
├── screens/                   # UI Screens
│   ├── home_screen.dart       # Main Controller Interface
│   └── settings_screen.dart   # Configuration Menu
├── services/                  # Business Logic
│   └── tcp_client.dart        # TCP Communication Layer
├── core/
│   ├── interfaces/            # Base Classes
│   │   └── base_controller.dart  <-- Plugin Interface
│   ├── services/
│   │   └── controller_registry.dart <-- Plugin Manager
│   └── models/
├── controllers/               # Controller Implementations
│   ├── touch_drive/           # Standard Touch Interface
│   ├── ps4/                   # PS4 Layout
│   └── ps5/                   # PS5 Layout
└── common/                    # Shared Widgets (Joystick, etc.)
```

---

## Developer Guide: Adding a Custom Controller

Want to add an Xbox controller or a custom robot interface? It's easy!

### 1. Create your Controller Class
Create a new file in `lib/controllers/my_custom_controller.dart`. Implement the `BaseController` interface.

```dart
import 'package:flutter/material.dart';
import '../../core/interfaces/base_controller.dart';
import '../../core/models/controller_state.dart';

class MyCustomController implements BaseController {
  @override
  String get id => 'custom_bot'; // Unique ID

  @override
  String get name => 'Custom Bot'; // Display Name

  @override
  IconData get icon => Icons.smart_toy; // Icon for Settings Menu

  @override
  Widget buildUI(BuildContext context, Function(ControllerState) onStateChanged) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
            // Update state: axes usually [-1.0 to 1.0], buttons [0 or 1]
            onStateChanged(ControllerState(
                type: id,
                axes: [1.0, 0.0], 
                buttons: [1, 0, 0]
            ));
        },
        child: Text('Move Forward'),
      ),
    );
  }
}
```

### 2. Register your Controller
Open `lib/main.dart` and add your controller to the registry.

```dart
void main() {
  // ... initialization ...
  final registry = ControllerRegistry();
  registry.register(TouchDriveController());
  registry.register(PS4Controller());
  registry.register(PS5Controller());
  
  // Register your new controller here
  registry.register(MyCustomController()); 
  
  runApp(const MyApp());
}
```

**That's it!** Your controller will now appear in the Settings menu dropdown.

---

## Installation & Setup

### Requirements
- Flutter SDK 3.x+
- Android Studio / VS Code
- Android Device (Minimum API 21)

### Steps
1. **Clone the repo**:
   ```bash
   git clone https://github.com/yourusername/vehicle_controller_app.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run on device**:
   ```bash
   flutter run --release
   ```

### Troubleshooting
**Crash on Startup (Adreno GPUs)**:
If the app crashes on launch (common on Redmi/Xiaomi devices), it's likely a generic Vulkan issue. We have already disabled Impeller in `AndroidManifest.xml` to fix this.
```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="false" />
```

---

## Data Protocol

The app sends JSON packets over TCP at 50Hz.

**Note on PS4/PS5 Data**:
- **Axes**: [LeftStickX, LeftStickY, RightStickX, RightStickY, L2, R2]
- **Buttons**: [Cross, Circle, Triangle, Square, L1, R1, Share, Options, PS, L3, R3, Up, Down, Left, Right]

```json
{
  "type": "ps4",
  "axes": [0.0, -1.0, 0.5, 0.0, 0.0, 1.0],
  "buttons": [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
}
```
