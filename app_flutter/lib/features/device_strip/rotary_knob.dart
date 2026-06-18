import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'device_knob_sizes.dart';

/// Knob dial geometry — 0 at south-west, max at south-east (clockwise over the
/// top; bottom 120° is empty).
abstract final class KnobArcGeometry {
  static const double start = math.pi * (5.0 / 6.0); // 150° — south-west
  static const double sweep = math.pi * (4.0 / 3.0); // +240° clockwise → south-east

  static double indicatorAngle(double value) =>
      start + value.clamp(0.0, 1.0) * sweep;
}

/// Compact rotary control styled after Bitwig / FL Studio Mobile device knobs.
class RotaryKnob extends StatefulWidget {
  const RotaryKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.displayValue,
    this.size = DeviceKnobSizes.strip,
    this.accentColor = const Color(0xFFE8A54B),
    this.modulationActive = false,
    this.modulationAmount = 0.0,
    this.connectModeActive = false,
    this.onModulationAssign,
    this.linkModeActive = false,
    this.linkModeAccent = const Color(0xFFB48CFF),
    this.onLinkTap,
    this.onAutomateRequest,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? displayValue;
  final double size;
  final Color accentColor;
  final bool modulationActive;
  final double modulationAmount;
  final bool connectModeActive;
  /// Called in connect mode after a long-press drag gesture completes.
  /// The [double] is the modulation amount (-1.0 to 1.0).
  final ValueChanged<double>? onModulationAssign;
  final bool linkModeActive;
  final Color linkModeAccent;
  final VoidCallback? onLinkTap;
  final VoidCallback? onAutomateRequest;

  @override
  State<RotaryKnob> createState() => _RotaryKnobState();
}

class _RotaryKnobState extends State<RotaryKnob>
    with SingleTickerProviderStateMixin {
  double _dragStartValue = 0;
  double _dragStartY = 0;
  bool _highlightsVisible = true;

  // Modulation assignment gesture state (connect mode)
  bool _assignmentMode = false;
  double _assignmentAmount = 0.0;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.connectModeActive || widget.linkModeActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant RotaryKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pulseActive = widget.connectModeActive || widget.linkModeActive;
    final oldPulseActive = oldWidget.connectModeActive || oldWidget.linkModeActive;
    if (pulseActive && !oldPulseActive) {
      _pulseController.repeat(reverse: true);
    } else if (!pulseActive && oldPulseActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // --- Normal knob drag (changes value) ---

  void _onDragStart(DragStartDetails details) {
    _dragStartValue = widget.value;
    _dragStartY = details.localPosition.dy;
    // In connect mode the long-press handles the modulation gesture;
    // plain drags still change the value normally.
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final sensitivity = 120.0 + widget.size * 2;
    final delta = (_dragStartY - details.localPosition.dy) / sensitivity;
    widget.onChanged((_dragStartValue + delta).clamp(0.0, 1.0));
  }

  void _onDragEnd(DragEndDetails details) {
    // Not involved in connect-mode gesture — long-press handles it.
  }

  void _onDragCancel() {}

  // --- Connect-mode long-press modulation assignment ---

  void _onLongPressStart(LongPressStartDetails details) {
    if (widget.linkModeActive) return;
    if (!widget.connectModeActive) {
      if (widget.onAutomateRequest != null) {
        HapticFeedback.mediumImpact();
        widget.onAutomateRequest!.call();
      }
      return;
    }
    HapticFeedback.mediumImpact();
    _pulseController.stop();
    _assignmentAmount = 0.0;
    _dragStartY = details.localPosition.dy; // reuse for assignment drag origin
    setState(() {
      _highlightsVisible = false;
      _assignmentMode = true;
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_assignmentMode) return;
    // Sensitivity: 200 px vertical travel = 1.0 amount (full range)
    const sensitivity = 200.0;
    final dy = details.localPosition.dy - _dragStartY;
    final amount = (-dy / sensitivity).clamp(-1.0, 1.0);
    setState(() => _assignmentAmount = amount);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_assignmentMode) return;
    widget.onModulationAssign?.call(_assignmentAmount);
    _pulseController.reset();
    if (widget.connectModeActive || widget.linkModeActive) {
      _pulseController.repeat(reverse: true);
    }
    setState(() {
      _highlightsVisible = true;
      _assignmentMode = false;
      _assignmentAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stroke = widget.size >= DeviceKnobSizes.editor ? 4.0 : 3.0;
    final theme = Theme.of(context);
    final angle = KnobArcGeometry.indicatorAngle(widget.value);
    final labelSize = widget.size >= DeviceKnobSizes.strip ? 10.0 : 9.0;
    final pulseAccent =
        widget.linkModeActive ? widget.linkModeAccent : widget.accentColor;
    final showConnectPulse =
        (widget.connectModeActive || widget.linkModeActive) && _highlightsVisible;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.linkModeActive ? widget.onLinkTap : null,
          onLongPressStart: widget.linkModeActive ? null : _onLongPressStart,
          onLongPressMoveUpdate: widget.linkModeActive ? null : _onLongPressMoveUpdate,
          onLongPressEnd: widget.linkModeActive ? null : _onLongPressEnd,
          onVerticalDragStart: widget.linkModeActive ? null : _onDragStart,
          onVerticalDragUpdate: widget.linkModeActive ? null : _onDragUpdate,
          onVerticalDragEnd: widget.linkModeActive ? null : _onDragEnd,
          onVerticalDragCancel: widget.linkModeActive ? null : _onDragCancel,
          onDoubleTap: widget.linkModeActive ? null : () => widget.onChanged(0.5),
          child: SizedBox(
            width: widget.size + 8,
            height: widget.size + 4,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final showGlow = showConnectPulse;
                return CustomPaint(
                  painter: showGlow
                      ? _BackgroundGlowPainter(
                          glowColor: pulseAccent
                              .withValues(alpha: _pulseAnimation.value),
                          borderRadius: 8,
                        )
                      : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: CustomPaint(
                          painter: _KnobPainter(
                            value: widget.value.clamp(0, 1),
                            angle: angle,
                            accentColor: pulseAccent,
                            strokeWidth: stroke,
                            modulationActive: widget.modulationActive,
                            modulationAmount: widget.modulationAmount,
                            connectModeActive: showConnectPulse,
                            assignmentMode: _assignmentMode,
                            assignmentAmount: _assignmentAmount,
                          ),
                        ),
                      ),
                      if (widget.displayValue != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.displayValue!,
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: widget.accentColor,
                                fontSize: widget.size * 0.17,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white54,
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter({
    required this.value,
    required this.angle,
    required this.accentColor,
    this.strokeWidth = 3,
    this.modulationActive = false,
    this.modulationAmount = 0.0,
    this.connectModeActive = false,
    this.assignmentMode = false,
    this.assignmentAmount = 0.0,
  });

  final double value;
  final double angle;
  final Color accentColor;
  final double strokeWidth;
  final bool modulationActive;
  final double modulationAmount;
  final bool connectModeActive;
  final bool assignmentMode;
  final double assignmentAmount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // --- Track arc ---
    // If connectModeActive, draw the whole track in accent with 30% alpha
    final trackPaint = Paint()
      ..color = connectModeActive
          ? accentColor.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      arcRect,
      KnobArcGeometry.start,
      KnobArcGeometry.sweep,
      false,
      trackPaint,
    );

    // --- Value arc ---
    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      arcRect,
      KnobArcGeometry.start,
      value * KnobArcGeometry.sweep,
      false,
      arcPaint,
    );

    // --- Modulation range arc (centered on current value) ---
    if (modulationActive && modulationAmount != 0.0) {
      final modLow = (value - modulationAmount.abs()).clamp(0.0, 1.0);
      final modHigh = (value + modulationAmount.abs()).clamp(0.0, 1.0);
      final modStartAngle = KnobArcGeometry.indicatorAngle(modLow);
      final modSweepAngle =
          KnobArcGeometry.indicatorAngle(modHigh) - modStartAngle;

      final modRect = connectModeActive
          ? Rect.fromCircle(center: center, radius: radius + strokeWidth)
          : arcRect;
      final modPaint = Paint()
        ..color = connectModeActive
            ? Colors.white.withValues(alpha: 0.5)
            : accentColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth * 0.5;
      canvas.drawArc(modRect, modStartAngle, modSweepAngle, false, modPaint);
    }

    // --- Assignment arc (connect-mode long-press drag visual) ---
    if (assignmentMode && assignmentAmount != 0.0) {
      final target = (value + assignmentAmount).clamp(0.0, 1.0);
      final fromAngle = KnobArcGeometry.indicatorAngle(value);
      final toAngle = KnobArcGeometry.indicatorAngle(target);
      final startA = math.min(fromAngle, toAngle);
      final sweepA = (toAngle - fromAngle).abs();

      final assignRect = Rect.fromCircle(
        center: center,
        radius: radius + strokeWidth,
      );
      final assignPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth * 0.7;
      canvas.drawArc(assignRect, startA, sweepA, false, assignPaint);
    }

    // --- Indicator dot ---
    final indicatorPaint = Paint()..color = accentColor;
    final indicatorEnd = Offset(
      center.dx + math.cos(angle) * (radius - 4),
      center.dy + math.sin(angle) * (radius - 4),
    );
    canvas.drawCircle(indicatorEnd, 2.5, indicatorPaint);

    // --- Center fill ---
    final fillPaint = Paint()..color = const Color(0xFF14141C);
    canvas.drawCircle(center, radius - 6, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.angle != angle ||
        oldDelegate.modulationActive != modulationActive ||
        oldDelegate.modulationAmount != modulationAmount ||
        oldDelegate.connectModeActive != connectModeActive ||
        oldDelegate.assignmentMode != assignmentMode ||
        oldDelegate.assignmentAmount != assignmentAmount;
  }
}

/// Paints a rounded-rect background glow behind the knob.
class _BackgroundGlowPainter extends CustomPainter {
  _BackgroundGlowPainter({
    required this.glowColor,
    required this.borderRadius,
  });

  final Color glowColor;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final paint = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundGlowPainter oldDelegate) {
    return oldDelegate.glowColor != glowColor;
  }
}