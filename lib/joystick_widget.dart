import 'dart:math' as math;
import 'package:flutter/material.dart';

class JoystickWidget extends StatefulWidget {
  final Function(double x, double y) onChanged;
  final double size;

  const JoystickWidget({
    super.key,
    required this.onChanged,
    this.size = 200,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget>
    with SingleTickerProviderStateMixin {
  double _x = 0.0; // Output value (curved and scaled)
  double _visualX = 0.0; // Visual position (full range)
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePosition(Offset localPosition) {
    // Optimized: Cache calculations
    final center = widget.size * 0.5;
    final maxRadius = center - 24.0; // thumbRadius constant
    
    // Check if touch is within the joystick circle
    final dx = localPosition.dx - center;
    final dy = localPosition.dy - center;
    
    // Calculate raw input value (-1.0 to 1.0) for visual position
    double rawVisualX = 0.0;
    double outputX = 0.0;
    
    // Optimized: Only calculate if there's actual movement
    if (dx.abs() > 0.001 || dy.abs() > 0.001) {
      // Normalize to -1.0 to 1.0 range for visual
      rawVisualX = (dx / maxRadius).clamp(-1.0, 1.0);
      
      // Optimized: Apply exponential curve (x^1.5 = x * sqrt(x) is faster than pow)
      final absX = rawVisualX.abs();
      final curvedX = rawVisualX >= 0 
          ? absX * math.sqrt(absX)  // Faster than pow(x, 1.5)
          : -absX * math.sqrt(absX);
      
      // Output uses full -1 to 1 range (curved but full range)
      outputX = curvedX;
    }
    
    // Smooth interpolation with higher factor for more responsive feel
    const lerpFactor = 0.6; // Made const for optimization
    final smoothedVisualX = _visualX + (rawVisualX - _visualX) * lerpFactor;
    final smoothedOutputX = _x + (outputX - _x) * lerpFactor;
    
    // Optimized: Only call setState if values actually changed significantly
    if ((smoothedVisualX - _visualX).abs() > 0.001 || 
        (smoothedOutputX - _x).abs() > 0.001) {
      setState(() {
        _visualX = smoothedVisualX;
        _x = smoothedOutputX;
      });
      // Use smoothedOutputX directly to ensure callback gets the latest value
      widget.onChanged(smoothedOutputX, 0.0);
    } else if ((_x.abs() < 0.001 && _x != 0.0) || (_visualX.abs() < 0.001 && _visualX != 0.0)) {
      // If values are very close to 0, set to exactly 0 to avoid tiny residual values
      setState(() {
        _x = 0.0;
        _visualX = 0.0;
      });
      widget.onChanged(0.0, 0.0);
    }
  }

  void _returnToCenter() {
    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _x = 0.0;
        _visualX = 0.0;
      });
      widget.onChanged(0.0, 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _isDragging = true;
        // Don't update position on initial touch - dead zone will handle it
      },
      onPanUpdate: (details) {
        if (_isDragging) {
          _updatePosition(details.localPosition);
        }
      },
      onPanEnd: (details) {
        _isDragging = false;
        _returnToCenter();
      },
      onPanCancel: () {
        _isDragging = false;
        _returnToCenter();
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withAlpha((0.1 * 255).round()),
              Colors.white.withAlpha((0.05 * 255).round()),
              Colors.white.withAlpha((0.02 * 255).round()),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          border: Border.all(
            color: Colors.white.withAlpha((0.2 * 255).round()),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.4 * 255).round()),
              blurRadius: 20,
              offset: Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withAlpha((0.05 * 255).round()),
              blurRadius: 8,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Center crosshair - modern style
            Center(
              child: CustomPaint(
                painter: CrosshairPainter(),
                size: Size(widget.size, widget.size),
              ),
            ),
            // Movement range indicator - modern style
            Center(
              child: Container(
                width: widget.size * 0.65,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withAlpha((0.2 * 255).round()),
                      Colors.white.withAlpha((0.3 * 255).round()),
                      Colors.white.withAlpha((0.2 * 255).round()),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.3, 0.5, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Thumb - use AnimatedBuilder for smooth movement
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                // Smoothly animate back to center when not dragging
                final currentVisualX = _isDragging ? _visualX : _visualX * (1 - _animation.value);
                // Use 0.85 for visual range to keep thumb within circle, ensuring symmetric movement
                final visualX = currentVisualX.clamp(-1.0, 1.0) * 0.85;
                return Align(
                  alignment: Alignment(visualX, 0.0),
                  child: AnimatedScale(
                    scale: _isDragging ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                            Color(0xFF6366F1),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.3 * 255).round()),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6366F1).withAlpha((0.5 * 255).round()),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withAlpha((0.3 * 255).round()),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.white.withAlpha((0.1 * 255).round()),
                            blurRadius: 4,
                            offset: Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withAlpha((0.9 * 255).round()),
                                Colors.white.withAlpha((0.5 * 255).round()),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withAlpha((0.5 * 255).round()),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Modern crosshair with gradient effect
    final paint = Paint()
      ..color = Colors.white.withAlpha((0.15 * 255).round())
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal line with fade
    final horizontalPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withAlpha((0.2 * 255).round()),
          Colors.white.withAlpha((0.3 * 255).round()),
          Colors.white.withAlpha((0.2 * 255).round()),
          Colors.transparent,
        ],
        stops: [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, center.dy, size.width, 1))
      ..strokeWidth = 1.5;
    
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      horizontalPaint,
    );
    
    // Draw vertical line (centered, shorter for horizontal-only steering)
    canvas.drawLine(
      Offset(center.dx, center.dy - size.height * 0.1),
      Offset(center.dx, center.dy + size.height * 0.1),
      paint,
    );
    
    // Center dot
    canvas.drawCircle(
      center,
      3,
      Paint()
        ..color = Colors.white.withAlpha((0.4 * 255).round())
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
