import 'package:flutter/material.dart';

enum JoystickMode { horizontal, all }

class JoystickWidget extends StatefulWidget {
  final Function(double x, double y) onChanged;
  final double size;
  final JoystickMode mode;

  const JoystickWidget({
    super.key,
    required this.onChanged,
    this.size = 200,
    this.mode = JoystickMode.all,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget>
    with SingleTickerProviderStateMixin {
  double _x = 0.0; // Output value (-1.0 to 1.0)
  double _y = 0.0;
  Offset _dragPosition = Offset.zero; // Visual drag position relative to center
  bool _isDragging = false;
  late AnimationController _centerController;
  late Animation<Offset> _centerAnimation;

  @override
  void initState() {
    super.initState();
    _centerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _centerAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _centerController, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _centerController.dispose();
    super.dispose();
  }

  void _updatePosition(Offset localPosition) {
    final center = widget.size * 0.5;
    final maxRadius = (widget.size * 0.5) - 20.0; // Keep thumb inside

    // Calculate vector from center
    Offset vector = localPosition - Offset(center, center);
    double distance = vector.distance;

    // Clamp to max radius
    if (distance > maxRadius) {
      vector = Offset(
        (vector.dx / distance) * maxRadius,
        (vector.dy / distance) * maxRadius,
      );
    }

    // Constrain based on mode
    if (widget.mode == JoystickMode.horizontal) {
      vector = Offset(vector.dx, 0.0);
    }

    // Normalize to -1.0 to 1.0
    double normX = (vector.dx / maxRadius).clamp(-1.0, 1.0);
    double normY = (vector.dy / maxRadius).clamp(-1.0, 1.0);

    // Invert Y so up is negative (standard joystick mapping) or positive?
    // Usually Up is -1.0 in screen coords, but for vehicle control:
    // Forward (Gas) is often +1.0.
    // For standard Gamepad, Up is often -1.0 axis value.
    // Let's stick to standard screen coords (-1.0 is Up) and let the consumer invert if needed.

    // Linear response for "Professional" feel (1:1 mapping)
    // No smoothing (lerp) for instant response

    if (_x != normX || _y != normY) {
      setState(() {
        _dragPosition = vector;
        _x = normX;
        _y = normY;
      });
      widget.onChanged(_x, _y);
    }
  }

  void _onPanEnd() {
    _isDragging = false;
    // Animate back to center
    _centerAnimation = Tween<Offset>(
      begin: _dragPosition,
      end: Offset.zero,
    ).animate(_centerController);

    _centerController.reset();
    _centerController.forward().then((_) {
      setState(() {
        _dragPosition = Offset.zero;
        _dragPosition = Offset.zero;
        _x = 0.0;
        _y = 0.0;
      });
      widget.onChanged(0.0, 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _centerController.stop();
        _isDragging = true;
        _updatePosition(details.localPosition);
      },
      onPanUpdate: (details) {
        _updatePosition(details.localPosition);
      },
      onPanEnd: (_) => _onPanEnd(),
      onPanCancel: () => _onPanEnd(),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Technical dark background
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        child: Stack(
          children: [
            // Technical Grid / Crosshair
            CustomPaint(
              painter: TechnicalGuidePainter(),
              size: Size(widget.size, widget.size),
            ),

            // Thumb
            AnimatedBuilder(
              animation: _centerController,
              builder: (context, child) {
                final pos = _isDragging
                    ? _dragPosition
                    : _centerAnimation.value;
                return Center(
                  child: Transform.translate(
                    offset: pos,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // High contrast thumb
                        color: Colors.black,
                        border: Border.all(
                          color: Color(0xFF00D4AA), // Professional Teal/Cyan
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00D4AA).withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
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

class TechnicalGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal Guide
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);

    // Ticks
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    // Center tick
    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx, center.dy + 10),
      tickPaint,
    );

    // Range ticks
    canvas.drawLine(
      Offset(center.dx - radius * 0.5, center.dy - 5),
      Offset(center.dx - radius * 0.5, center.dy + 5),
      tickPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.5, center.dy - 5),
      Offset(center.dx + radius * 0.5, center.dy + 5),
      tickPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
