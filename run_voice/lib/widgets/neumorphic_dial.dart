import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class NeumorphicDial extends StatefulWidget {
  final double value; // valore corrente (es. secondi per km per il passo, oppure bpm)
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String label;
  final String Function(double value) valueFormatter;
  final double size;

  const NeumorphicDial({
    super.key,
    required this.value,
    this.min = 180.0, // 3:00 /km
    this.max = 480.0, // 8:00 /km
    this.step = 5.0,  // step di 5 secondi
    required this.onChanged,
    required this.label,
    required this.valueFormatter,
    this.size = 200,
  });

  @override
  State<NeumorphicDial> createState() => _NeumorphicDialState();
}

class _NeumorphicDialState extends State<NeumorphicDial> {
  late double _currentAngle;
  double? _lastPanAngle;
  double? _panStartAngle;
  double? _panStartValue;
  double _lastHapticStep = double.nan;

  @override
  void initState() {
    super.initState();
    _currentAngle = _valueToAngle(widget.value);
  }

  @override
  void didUpdateWidget(covariant NeumorphicDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentAngle = _valueToAngle(widget.value);
      _lastHapticStep = _snapValue(widget.value);
    }
  }

  double _valueToAngle(double val) {
    final clamped = val.clamp(widget.min, widget.max);
    final ratio = (clamped - widget.min) / (widget.max - widget.min);
    // Da -135° (top-left) a +135° (top-right), totale 270 gradi di rotazione
    return -135.0 + (ratio * 270.0);
  }

  double _snapValue(double rawValue) {
    final snapped = (rawValue / widget.step).round() * widget.step;
    return snapped.clamp(widget.min, widget.max);
  }

  double _angleToValue(double deg) {
    final clampedDeg = deg.clamp(-135.0, 135.0);
    final ratio = (clampedDeg - (-135.0)) / 270.0;
    final rawVal = widget.min + ratio * (widget.max - widget.min);
    return _snapValue(rawVal);
  }

  void _onPanStart(DragStartDetails details, Offset center) {
    final pos = details.localPosition - center;
    final angle = math.atan2(pos.dy, pos.dx) * 180 / math.pi;
    _lastPanAngle = angle;
    _panStartAngle = angle;
    _panStartValue = widget.value;
    _lastHapticStep = _snapValue(widget.value);
  }

  void _onPanUpdate(DragUpdateDetails details, Offset center) {
    final pos = details.localPosition - center;
    final currentPanAngle = math.atan2(pos.dy, pos.dx) * 180 / math.pi;

    if (_lastPanAngle != null) {
      double delta = currentPanAngle - _lastPanAngle!;
      // Normalizzazione angolo per salti da -180 a +180
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;

      final newAngle = (_currentAngle + delta).clamp(-135.0, 135.0);
      final newValue = _angleToValue(newAngle);

      if (newValue != widget.value) {
        if (newValue != _lastHapticStep) {
          HapticFeedback.selectionClick();
          _lastHapticStep = newValue;
        }
        widget.onChanged(newValue);
      }
      setState(() {
        _currentAngle = newAngle;
      });
    }
    _lastPanAngle = currentPanAngle;
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPanAngle = null;
    _panStartAngle = null;
    _panStartValue = null;
  }

  @override
  Widget build(BuildContext context) {
    final center = Offset(widget.size / 2, widget.size / 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanStart: (d) => _onPanStart(d, center),
          onPanUpdate: (d) => _onPanUpdate(d, center),
          onPanEnd: _onPanEnd,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neuDarkShadow.withValues(alpha: 0.92),
                  offset: const Offset(8, 8),
                  blurRadius: 18,
                ),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  offset: const Offset(-1, -1),
                  blurRadius: 18,
                ),
                BoxShadow(
                  color: AppColors.neuLightShadow.withValues(alpha: 0.55),
                  offset: const Offset(-7, -7),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Anello glow soft cyan/neon
                SizedBox(
                  width: widget.size * 0.88,
                  height: widget.size * 0.88,
                  child: CustomPaint(
                    painter: _DialArcPainter(
                      activeAngle: _currentAngle,
                    ),
                  ),
                ),
                // Tacche ad arco
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _DialTicksPainter(
                    minAngle: -135,
                    maxAngle: 135,
                    activeAngle: _currentAngle,
                  ),
                ),
                // Manopola interna centrale (Knob rotante)
                Transform.rotate(
                  angle: (_currentAngle) * math.pi / 180,
                  child: Container(
                    width: widget.size * 0.65,
                    height: widget.size * 0.65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLight,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.16),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neuDarkShadow.withValues(alpha: 0.82),
                          offset: const Offset(4, 4),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          offset: const Offset(-1, -1),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: AppColors.neuLightShadow.withValues(alpha: 0.45),
                          offset: const Offset(-3, -3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Indicatore luminoso sulla circonferenza del dial
                        Positioned(
                          top: 8,
                          left: (widget.size * 0.65) / 2 - 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Display centrale informativo (non ruotante)
                IgnorePointer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.valueFormatter(widget.value),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DialTicksPainter extends CustomPainter {
  final double minAngle;
  final double maxAngle;
  final double activeAngle;

  _DialTicksPainter({
    required this.minAngle,
    required this.maxAngle,
    required this.activeAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;

    const tickCount = 28;
    final angleStep = (maxAngle - minAngle) / tickCount;

    for (int i = 0; i <= tickCount; i++) {
      final deg = minAngle + i * angleStep;
      // Converti l'angolo in radianti (traslando di -90 gradi per posizionare 0 in alto)
      final rad = (deg - 90) * math.pi / 180;
      final isActive = deg <= activeAngle;

      final p1 = Offset(
        center.dx + radius * math.cos(rad),
        center.dy + radius * math.sin(rad),
      );
      final tickLength = (i % 4 == 0) ? 8.0 : 4.0;
      final p2 = Offset(
        center.dx + (radius - tickLength) * math.cos(rad),
        center.dy + (radius - tickLength) * math.sin(rad),
      );

      final paint = Paint()
        ..color = isActive
            ? AppColors.accent.withValues(alpha: 0.9)
            : AppColors.neuBorder.withValues(alpha: 0.5)
        ..strokeWidth = (i % 4 == 0) ? 2.2 : 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialTicksPainter oldDelegate) {
    return oldDelegate.activeAngle != activeAngle;
  }
}

class _DialArcPainter extends CustomPainter {
  final double activeAngle;

  _DialArcPainter({
    required this.activeAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final startRad = (-135 - 90) * math.pi / 180;
    final sweepRad = (activeAngle + 135).clamp(0, 270) * math.pi / 180;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          AppColors.accentDark,
          AppColors.accent,
          AppColors.accentLight,
        ],
      ).createShader(rect);

    canvas.drawArc(rect, startRad, sweepRad, false, paint);
  }

  @override
  bool shouldRepaint(covariant _DialArcPainter oldDelegate) {
    return oldDelegate.activeAngle != activeAngle;
  }
}
