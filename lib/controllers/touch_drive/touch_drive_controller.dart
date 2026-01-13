import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/interfaces/base_controller.dart';
import '../../core/models/controller_state.dart';
import '../../common/widgets/joystick_widget.dart';
import '../../common/widgets/gas_brake_widget.dart';
import '../../core/providers/settings_provider.dart';

class TouchDriveController implements BaseController {
  @override
  String get id => 'touch_drive';

  @override
  String get name => 'Touch Drive';

  @override
  IconData get icon => Icons.touch_app;

  @override
  Widget buildUI(
    BuildContext context,
    Function(ControllerState) onStateChanged,
  ) {
    return _TouchDriveUI(onStateChanged: onStateChanged);
  }
}

class _TouchDriveUI extends ConsumerStatefulWidget {
  final Function(ControllerState) onStateChanged;

  const _TouchDriveUI({required this.onStateChanged});

  @override
  ConsumerState<_TouchDriveUI> createState() => _TouchDriveUIState();
}

class _TouchDriveUIState extends ConsumerState<_TouchDriveUI> {
  // State
  double _steering = 0.0;
  double _gas = 0.0;
  double _brake = 0.0;
  String _gear = 'P';
  bool _autoMode = false;
  bool _leftBlinker = false;
  bool _rightBlinker = false;

  void _updateState() {
    // Map to standard axes and buttons
    // Axes: [Steering, Gas, Brake]
    final axes = [_steering, _gas, _brake];

    // Buttons: [LeftBlinker, RightBlinker, P, R, N, D, Auto]
    // 0: Left Blinker
    // 1: Right Blinker
    // 2: Park (1 if P, else 0)
    // 3: Reverse
    // 4: Neutral
    // 5: Drive
    // 6: Auto Mode
    final buttons = [
      _leftBlinker ? 1 : 0,
      _rightBlinker ? 1 : 0,
      _gear == 'P' ? 1 : 0,
      _gear == 'R' ? 1 : 0,
      _gear == 'N' ? 1 : 0,
      _gear == 'D' ? 1 : 0,
      _autoMode ? 1 : 0,
    ];

    widget.onStateChanged(
      ControllerState(type: 'touch_drive', axes: axes, buttons: buttons),
    );
  }

  void _onJoystickChanged(double x, double y) {
    final settings = ref.read(settingsProvider);
    double val = x;
    // Apply Deadzone
    if (val.abs() < settings.deadzone) {
      val = 0.0;
    } else {
      // Normalize
      // sign(val) * (abs(val) - deadzone) / (1 - deadzone)
      val =
          val.sign *
          (val.abs() - settings.deadzone) /
          (1.0 - settings.deadzone);
    }

    // Apply Sensitivity
    val = val * settings.steeringSensitivity;

    _steering = val.clamp(-1.0, 1.0);
    _updateState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final pedalHeight = (screenHeight * 0.6).clamp(200.0, 400.0);

        return Row(
          children: [
            // Left side - Joystick
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  top: 16,
                  right: 0,
                  bottom: 16,
                ),
                child: Align(
                  alignment: Alignment(
                    1.0,
                    0.0,
                  ), // Align to right (towards center)
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Reduced size for "smaller" look as requested
                      final joystickSize = constraints.maxHeight.clamp(
                        120.0,
                        200.0,
                      );
                      return JoystickWidget(
                        onChanged: (x, y) => _onJoystickChanged(x, y),
                        size: joystickSize,
                        mode: JoystickMode.horizontal,
                      );
                    },
                  ),
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
                    // Gear selection
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
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
                    ),

                    // Auto mode
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _autoMode
                              ? LinearGradient(
                                  colors: [
                                    Color(0xFF00D4AA),
                                    Color(0xFF00B894),
                                  ],
                                )
                              : null,
                          color: _autoMode
                              ? null
                              : Colors.white.withAlpha((0.08 * 255).round()),
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
                                    color: Color(
                                      0xFF00D4AA,
                                    ).withAlpha((0.3 * 255).round()),
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
                              _updateState();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 14,
                              ),
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
                    ),

                    // Blinkers
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBlinkerButton(true),
                          SizedBox(width: 16),
                          _buildBlinkerButton(false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right side - Gas and Brake
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
                          _gas = gas;
                          _brake = brake;
                          _updateState();
                        },
                        width: 80,
                        height: pedalHeight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
          _updateState();
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
            color: isSelected
                ? null
                : Colors.white.withAlpha((0.05 * 255).round()),
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
              _leftBlinker = !_leftBlinker;
              if (_leftBlinker) {
                _rightBlinker = false;
              }
            } else {
              _rightBlinker = !_rightBlinker;
              if (_rightBlinker) {
                _leftBlinker = false;
              }
            }
            _updateState();
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
            color: isActive
                ? null
                : Colors.white.withAlpha((0.08 * 255).round()),
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
              isLeft
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
