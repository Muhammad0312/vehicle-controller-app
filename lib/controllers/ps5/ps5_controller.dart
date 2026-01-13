import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/interfaces/base_controller.dart';
import '../../core/models/controller_state.dart';
import '../../common/widgets/joystick_widget.dart';
import '../../core/providers/settings_provider.dart';

class PS5Controller implements BaseController {
  @override
  String get id => 'ps5';

  @override
  String get name => 'PS5 Controller';

  @override
  IconData get icon => Icons.gamepad_outlined;

  @override
  Widget buildUI(
    BuildContext context,
    Function(ControllerState) onStateChanged,
  ) {
    return _PS5ControllerUI(onStateChanged: onStateChanged);
  }
}

class _PS5ControllerUI extends ConsumerStatefulWidget {
  final Function(ControllerState) onStateChanged;

  const _PS5ControllerUI({required this.onStateChanged});

  @override
  ConsumerState<_PS5ControllerUI> createState() => _PS5ControllerUIState();
}

class _PS5ControllerUIState extends ConsumerState<_PS5ControllerUI> {
  // State
  double _leftStickX = 0.0;
  double _leftStickY = 0.0;
  double _rightStickX = 0.0;
  double _rightStickY = 0.0;
  double _l2 = 0.0;
  double _r2 = 0.0;
  final List<bool> _buttons = List.filled(15, false); // 0-14

  void _updateState() {
    final axes = [
      _leftStickX,
      _leftStickY,
      _rightStickX,
      _rightStickY,
      _l2,
      _r2,
    ];

    final buttons = _buttons.map((b) => b ? 1 : 0).toList();

    widget.onStateChanged(
      ControllerState(type: 'ps5', axes: axes, buttons: buttons),
    );
  }

  double _processAxis(double val) {
    final settings = ref.read(settingsProvider);
    double newValue = val;

    // Deadzone
    if (newValue.abs() < settings.deadzone) {
      newValue = 0.0;
    } else {
      newValue =
          newValue.sign *
          ((newValue.abs() - settings.deadzone) / (1.0 - settings.deadzone));
    }

    // Sensitivity
    newValue = newValue * settings.steeringSensitivity;

    return newValue.clamp(-1.0, 1.0);
  }

  void _setButton(int index, bool pressed) {
    if (_buttons[index] != pressed) {
      setState(() {
        _buttons[index] = pressed;
      });
      _updateState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Calculate safe zones and sizes
        final joystickSize = (h * 0.4).clamp(120.0, 180.0);
        final buttonSize = (h * 0.15).clamp(40.0, 60.0);

        return Container(
          color: Colors.black, // Match global theme
          child: Stack(
            children: [
              // L2 Trigger (Left Top)
              Positioned(
                top: 60, // Avoid global UI
                left: 20,
                child: _buildTechnicalTrigger('L2', _l2, (val) {
                  _l2 = val;
                  _updateState();
                }),
              ),

              // R2 Trigger (Right Top)
              Positioned(
                top: 60, // Avoid global UI
                right: 20,
                child: _buildTechnicalTrigger('R2', _r2, (val) {
                  _r2 = val;
                  _updateState();
                }),
              ),

              // D-Pad (Left Side)
              Positioned(
                left: w * 0.15,
                top: h * 0.25,
                child: _buildDPad(buttonSize),
              ),

              // Action Buttons (Right Side)
              Positioned(
                right: w * 0.15,
                top: h * 0.25,
                child: _buildActionButtons(buttonSize),
              ),

              // Joysticks (Bottom Center)
              Positioned(
                left: w * 0.3,
                bottom: 20,
                child: JoystickWidget(
                  size: joystickSize,
                  mode: JoystickMode.all,
                  onChanged: (x, y) {
                    _leftStickX = _processAxis(x);
                    _leftStickY = _processAxis(y);
                    _updateState();
                  },
                ),
              ),
              Positioned(
                right: w * 0.3,
                bottom: 20,
                child: JoystickWidget(
                  size: joystickSize,
                  mode: JoystickMode.all,
                  onChanged: (x, y) {
                    _rightStickX = _processAxis(x);
                    _rightStickY = _processAxis(y);
                    _updateState();
                  },
                ),
              ),

              // Center Buttons (Create, Options, PS)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTechnicalSmallButton('CREATE', 6), // Share -> Create
                    SizedBox(width: 80),
                    _buildTechnicalSmallButton('OPTIONS', 7),
                  ],
                ),
              ),

              // PS Button
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(child: _buildPSButton(8)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTechnicalTrigger(
    String label,
    double value,
    Function(double) onChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.blueAccent.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            shadows: [
              Shadow(
                color: Colors.blueAccent.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: 6),
        GestureDetector(
          onVerticalDragStart: (details) {
            final val = (details.localPosition.dy / 120.0).clamp(0.0, 1.0);
            onChanged(val);
          },
          onVerticalDragUpdate: (details) {
            final val = (details.localPosition.dy / 120.0).clamp(0.0, 1.0);
            onChanged(val);
          },
          onVerticalDragEnd: (_) {
            onChanged(0.0);
          },
          onVerticalDragCancel: () {
            onChanged(0.0);
          },
          child: Container(
            width: 60,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withAlpha((0.1 * 255).round()),
                  Colors.white.withAlpha((0.05 * 255).round()),
                ],
              ),
              border: Border.all(
                color: Colors.white.withAlpha((0.2 * 255).round()),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.5 * 255).round()),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Fill
                  AnimatedContainer(
                    duration: Duration(milliseconds: 50),
                    width: double.infinity,
                    height: 120 * value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blueAccent,
                          Color(0xFF2979FF), // Blue 400
                        ],
                      ),
                      boxShadow: value > 0.05
                          ? [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  // Grip lines
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      8,
                      (index) => Center(
                        child: Container(
                          height: 2,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDPad(double size) {
    return Column(
      children: [
        _buildDPadBtn(Icons.arrow_drop_up, 11, size),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDPadBtn(Icons.arrow_left, 13, size),
            SizedBox(width: size), // Space for center
            _buildDPadBtn(Icons.arrow_right, 14, size),
          ],
        ),
        _buildDPadBtn(Icons.arrow_drop_down, 12, size),
      ],
    );
  }

  Widget _buildDPadBtn(IconData icon, int index, double size) {
    final pressed = _buttons[index];
    return GestureDetector(
      onTapDown: (_) => _setButton(index, true),
      onTapUp: (_) => _setButton(index, false),
      onTapCancel: () => _setButton(index, false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: pressed
              ? Colors.blueAccent.withValues(alpha: 0.3)
              : Colors.black,
          border: Border.all(
            color: pressed ? Colors.blueAccent : Colors.white24,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          color: pressed ? Colors.blueAccent : Colors.white54,
          size: size * 0.6,
        ),
      ),
    );
  }

  Widget _buildActionButtons(double size) {
    return SizedBox(
      width: size * 3,
      height: size * 3,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _buildActionBtn('△', 2, Colors.greenAccent, size),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildActionBtn('✕', 0, Colors.blueAccent, size),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildActionBtn('▢', 3, Colors.pinkAccent, size),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _buildActionBtn('○', 1, Colors.redAccent, size),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, int index, Color color, double size) {
    final pressed = _buttons[index];
    // PS5 buttons are usually transparent with white symbols, but we stick to technical neon
    return GestureDetector(
      onTapDown: (_) => _setButton(index, true),
      onTapUp: (_) => _setButton(index, false),
      onTapCancel: () => _setButton(index, false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: pressed ? color.withValues(alpha: 0.3) : Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: pressed ? color : Colors.white24, width: 2),
          boxShadow: pressed
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: pressed ? color : color.withValues(alpha: 0.7),
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicalSmallButton(String label, int index) {
    final pressed = _buttons[index];
    return GestureDetector(
      onTapDown: (_) => _setButton(index, true),
      onTapUp: (_) => _setButton(index, false),
      onTapCancel: () => _setButton(index, false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: pressed ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPSButton(int index) {
    final pressed = _buttons[index];
    return GestureDetector(
      onTapDown: (_) => _setButton(index, true),
      onTapUp: (_) => _setButton(index, false),
      onTapCancel: () => _setButton(index, false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          border: Border.all(
            color: pressed ? Colors.blueAccent : Colors.white24,
            width: 2,
          ),
          boxShadow: pressed
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Icon(Icons.gamepad_outlined, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
