# Covolv Controller

A professional Flutter mobile application for vehicle control with real-time TCP communication. The app provides intuitive controls for steering, acceleration, braking, and vehicle systems, designed for landscape-only operation.

## Features

### Vehicle Controls
- **Joystick Steering**: Professional-feeling horizontal steering control with exponential response curve
  - Output range: -1.0 (full left) to +1.0 (full right)
  - Smooth interpolation for responsive control
  - Visual feedback with modern glassmorphism design

- **Gas & Brake Pedals**: Vertical slider controls for acceleration and braking
  - Output range: 0.0 (released) to 1.0 (fully pressed)
  - Real-time visual feedback with gradient fills
  - Independent control for each pedal

- **Gear Selection**: Quick-access buttons for gear changes
  - Park (P), Drive (D), Neutral (N), Reverse (R)
  - Visual indicators for current selection

- **Auto Mode**: Toggle for autonomous driving mode

- **Blinkers**: Left and right turn signal controls
  - Mutual exclusivity (only one can be active at a time)

### Technical Features
- **TCP Communication**: Real-time data transmission at 50 Hz (20ms intervals)
- **Auto-Reconnect**: Automatic reconnection on connection loss
- **Settings Management**: Persistent IP and port configuration
- **Landscape-Only**: Forced landscape orientation with immersive mode
- **Modern UI**: Glassmorphism design with smooth animations
- **Performance Optimized**: Efficient state management and minimal rebuilds

## Requirements

- Flutter SDK 3.10.7 or higher
- Dart SDK 3.10.7 or higher
- Android device/emulator (Android 5.0+)
- iOS device/simulator (iOS 12.0+) - optional
- Network connection (same network as TCP server)

## Installation

1. **Clone the repository** (if applicable):
   ```bash
   git clone <repository-url>
   cd flutter_application_1
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate app icons** (if needed):
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Configuration

### Initial Setup

1. **Configure TCP Server**:
   - Open the app
   - Tap the settings icon (gear) in the top-right corner
   - Enter your PC's IP address (e.g., `192.168.1.100`)
   - Enter the port number (default: `8080`)
   - Tap "Save Settings"

2. **Start the Dashboard** (optional but recommended):
   ```bash
   python dashboard.py --host 0.0.0.0 --port 8080
   ```
   See [README_DASHBOARD.md](README_DASHBOARD.md) for dashboard details.

### Network Setup

- Ensure your phone and PC are on the same Wi-Fi network
- Find your PC's IP address:
  - **Windows**: `ipconfig` (look for IPv4 Address)
  - **Linux/Mac**: `ifconfig` or `ip addr` (look for inet address)
- Configure firewall to allow incoming connections on the specified port

## Usage

### Basic Operation

1. **Launch the app** - It will automatically attempt to connect to the configured TCP server
2. **Connection Status** - Check the top status indicator:
   - 🟢 **Connected**: Ready to send data
   - 🟡 **Connecting...**: Attempting to connect
   - 🔴 **Disconnected**: Connection lost, will auto-reconnect

3. **Control the Vehicle**:
   - **Steering**: Drag the joystick left/right on the right side of the screen
   - **Gas**: Drag up on the left gas pedal
   - **Brake**: Drag up on the left brake pedal
   - **Gear**: Tap the gear buttons in the center
   - **Auto Mode**: Toggle the auto mode button
   - **Blinkers**: Tap left or right blinker buttons

### Data Transmission

The app sends JSON data at 50 Hz (20ms intervals) when connected:

```json
{
  "steering": {
    "x": -0.75,
    "y": 0.0
  },
  "gas": 0.45,
  "brake": 0.0,
  "gear": "D",
  "autoMode": false,
  "leftBlinker": false,
  "rightBlinker": true,
  "timestamp": 1234567890123
}
```

**Data Ranges**:
- `steering.x`: -1.0 (full left) to +1.0 (full right)
- `steering.y`: Always 0.0 (horizontal-only steering)
- `gas`: 0.0 (released) to 1.0 (fully pressed)
- `brake`: 0.0 (released) to 1.0 (fully pressed)
- `gear`: "P", "D", "N", or "R"
- `autoMode`: `true` or `false`
- `leftBlinker`: `true` or `false`
- `rightBlinker`: `true` or `false`
- `timestamp`: Milliseconds since epoch

## Architecture

### Project Structure

```
lib/
├── main.dart              # Main app entry, UI layout, state management
├── joystick_widget.dart   # Joystick control widget with steering logic
├── gas_brake_widget.dart  # Gas and brake pedal controls
├── tcp_client.dart       # TCP communication and auto-reconnect logic
└── settings_screen.dart   # Settings UI for IP/port configuration

assets/
└── icons/
    └── covolv.png        # App logo

dashboard.py              # Python dashboard for monitoring (optional)
```

### Key Components

- **TCPClient**: Manages TCP connection, auto-reconnect, and data transmission
- **JoystickWidget**: Custom joystick with exponential response curve
- **GasBrakeWidget**: Dual vertical slider controls
- **SettingsScreen**: Persistent configuration management

## Troubleshooting

### Connection Issues

**Problem**: App shows "Disconnected" or "Connecting..."
- ✅ Verify phone and PC are on the same Wi-Fi network
- ✅ Check IP address is correct in settings
- ✅ Ensure TCP server is running and listening on the correct port
- ✅ Check firewall settings on PC
- ✅ Try restarting the app

**Problem**: Connection works but data isn't being received
- ✅ Verify the TCP server is reading from the socket correctly
- ✅ Check that data format matches expected JSON structure
- ✅ Monitor network traffic to confirm data is being sent

### Performance Issues

**Problem**: App feels laggy or unresponsive
- ✅ Close other apps to free up memory
- ✅ Ensure device has sufficient RAM
- ✅ Check for background processes consuming resources

### UI Issues

**Problem**: Controls don't respond or feel jumpy
- ✅ Ensure you're dragging within the control area
- ✅ Try releasing and re-pressing controls
- ✅ Restart the app if issues persist

## Development

### Building for Release

**Android APK**:
```bash
flutter build apk --release
```

**Android App Bundle**:
```bash
flutter build appbundle --release
```

**iOS** (requires Mac and Xcode):
```bash
flutter build ios --release
```

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

## Dependencies

- `flutter`: SDK
- `shared_preferences: ^2.2.2`: Persistent settings storage
- `flutter_launcher_icons: ^0.13.1`: App icon generation (dev dependency)

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]

## Support

For issues, questions, or feature requests, please [open an issue](link-to-issues) or contact [your contact info].

---

**Note**: This app is designed for vehicle control systems. Ensure proper safety measures and testing before use in real-world scenarios.
