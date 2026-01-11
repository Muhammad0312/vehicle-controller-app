import 'package:flutter/material.dart';

class GasBrakeWidget extends StatefulWidget {
  final Function(double gas, double brake) onChanged;
  final double width;
  final double height;

  const GasBrakeWidget({
    super.key,
    required this.onChanged,
    this.width = 100,
    this.height = 300,
  });

  @override
  State<GasBrakeWidget> createState() => _GasBrakeWidgetState();
}

class _GasBrakeWidgetState extends State<GasBrakeWidget> {
  double _gas = 0.0;
  double _brake = 0.0;
  bool _isDraggingGas = false;
  bool _isDraggingBrake = false;

  void _updateGas(Offset localPosition) {
    // Calculate gas value: 0.0 at bottom, 1.0 at top
    // Use max to ensure we can reach exactly 1.0 when at the very top
    final normalizedDy = (localPosition.dy / widget.height).clamp(0.0, 1.0);
    final newGas = (1.0 - normalizedDy).clamp(0.0, 1.0);
    // Update if value changed (reduced threshold to allow reaching 1.0)
    if ((newGas - _gas).abs() > 0.005 || newGas == 1.0 || newGas == 0.0) {
      setState(() {
        _gas = newGas;
      });
      widget.onChanged(_gas, _brake);
    }
  }

  void _updateBrake(Offset localPosition) {
    // Calculate brake value: 0.0 at bottom, 1.0 at top
    // Use max to ensure we can reach exactly 1.0 when at the very top
    final normalizedDy = (localPosition.dy / widget.height).clamp(0.0, 1.0);
    final newBrake = (1.0 - normalizedDy).clamp(0.0, 1.0);
    // Update if value changed (reduced threshold to allow reaching 1.0)
    if ((newBrake - _brake).abs() > 0.005 || newBrake == 1.0 || newBrake == 0.0) {
      setState(() {
        _brake = newBrake;
      });
      widget.onChanged(_gas, _brake);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gas pedal
          SizedBox(
            width: widget.width,
            child: GestureDetector(
              onPanStart: (details) {
                _isDraggingGas = true;
                _updateGas(details.localPosition);
              },
              onPanUpdate: (details) {
                if (_isDraggingGas) {
                  _updateGas(details.localPosition);
                }
              },
              onPanEnd: (details) {
                _isDraggingGas = false;
                setState(() {
                  _gas = 0.0;
                });
                widget.onChanged(0.0, _brake);
              },
              onPanCancel: () {
                _isDraggingGas = false;
                setState(() {
                  _gas = 0.0;
                });
                widget.onChanged(0.0, _brake);
              },
              child: Container(
                width: widget.width,
                height: widget.height,
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
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.3 * 255).round()),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      // Gas fill with gradient
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 50),
                          width: double.infinity,
                          height: widget.height * _gas,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF00D4AA),
                                Color(0xFF00B894),
                              ],
                            ),
                            boxShadow: _gas > 0.1
                                ? [
                                    BoxShadow(
                                      color: Color(0xFF00D4AA).withAlpha((0.5 * 255).round()),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      // Label
                      Center(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            'GAS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: Colors.white.withAlpha((0.8 * 255).round()),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha((0.3 * 255).round()),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 20),
          // Brake pedal
          SizedBox(
            width: widget.width,
            child: GestureDetector(
              onPanStart: (details) {
                _isDraggingBrake = true;
                _updateBrake(details.localPosition);
              },
              onPanUpdate: (details) {
                if (_isDraggingBrake) {
                  _updateBrake(details.localPosition);
                }
              },
              onPanEnd: (details) {
                _isDraggingBrake = false;
                setState(() {
                  _brake = 0.0;
                });
                widget.onChanged(_gas, 0.0);
              },
              onPanCancel: () {
                _isDraggingBrake = false;
                setState(() {
                  _brake = 0.0;
                });
                widget.onChanged(_gas, 0.0);
              },
              child: Container(
                width: widget.width,
                height: widget.height,
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
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.3 * 255).round()),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      // Brake fill with gradient
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 50),
                          width: double.infinity,
                          height: widget.height * _brake,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFF6B6B),
                                Color(0xFFEE5A6F),
                              ],
                            ),
                            boxShadow: _brake > 0.1
                                ? [
                                    BoxShadow(
                                      color: Color(0xFFFF6B6B).withAlpha((0.5 * 255).round()),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      // Label
                      Center(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            'BRAKE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: Colors.white.withAlpha((0.8 * 255).round()),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha((0.3 * 255).round()),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
