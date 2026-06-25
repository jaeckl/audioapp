import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'modulator_math.dart';
import 'modulator_rate_codec.dart';
import 'modulator_types.dart';
import 'rotary_knob.dart';

/// Properties panel for the Curve (user-drawn breakpoint) modulator.
class CurvePropertiesPanel extends StatelessWidget {
  const CurvePropertiesPanel({
    super.key,
    required this.mod,
    required this.onUpdate,
    this.onOpenEditor,
  });

  final LfoSnapshot mod;
  final Future<void> Function(String param, double value) onUpdate;
  final VoidCallback? onOpenEditor;

  static const accent = Color(0xFFE8A54B);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF14141C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: _header(),
          ),
          const SizedBox(height: 6),
          // Preview widget
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: onOpenEditor,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CustomPaint(
                    painter: _CurvePreviewPainter(
                      positions: mod.curveBpPositions,
                      values: mod.curveBpValues,
                      polarity: mod.polarity,
                      accent: accent,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Retrigger bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: _retriggerBar(),
          ),
          // Knobs
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: _knobs(),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Text(
          'CURVE ${mod.id}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        // Polarity toggle
        SizedBox(
          width: 38,
          height: 22,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF14141C),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(2, (i) {
                  final active = mod.polarity.clamp(0, 1) == i;
                  return Expanded(
                    child: Material(
                      color: active ? accent.withValues(alpha: 0.2) : Colors.transparent,
                      child: InkWell(
                        onTap: () => onUpdate('polarity', i.toDouble()),
                        child: Center(
                          child: Text(
                            ['\u00B1', '+'][i],
                            style: TextStyle(
                              color: active ? accent : Colors.white38,
                              fontSize: 9,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _retriggerBar() {
    const labels = ['Free', 'Sync', 'On note'];
    const values = [0, 1, 2];
    final selected = mod.retrigger.clamp(0, 2);
    return SizedBox(
      height: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF14141C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(3, (i) {
              final active = selected == values[i];
              return Expanded(
                child: Material(
                  color: active ? accent.withValues(alpha: 0.2) : Colors.transparent,
                  child: InkWell(
                    onTap: () => onUpdate('retrigger', values[i].toDouble()),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: active ? accent : Colors.white38,
                          fontSize: 9,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _knobs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Center(
            child: RotaryKnob(
              label: 'Rate',
              value: mod.rate.clamp(0.0, 1.0),
              displayValue: ModulatorRateCodec.formatRate(mod),
              size: DeviceKnobSizes.compact,
              accentColor: accent,
              onChanged: (v) => onUpdate('rate', v),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: RotaryKnob(
              label: 'Smooth',
              value: mod.smoothing.clamp(0.0, 1.0),
              displayValue: '${(mod.smoothing * 100).round()}%',
              size: DeviceKnobSizes.compact,
              accentColor: accent,
              onChanged: (v) => onUpdate('smoothing', v),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints a breakpoint curve preview in the properties panel.
class _CurvePreviewPainter extends CustomPainter {
  _CurvePreviewPainter({
    required this.positions,
    required this.values,
    required this.polarity,
    required this.accent,
  });

  final List<double> positions;
  final List<double> values;
  final int polarity;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1A1A24);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Center line (for bipolar)
    if (polarity == 0) {
      final centerY = size.height / 2;
      canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY),
          Paint()..color = Colors.white.withValues(alpha: 0.1)..strokeWidth = 0.5);
    }

    final count = positions.length;
    if (count < 2) return;

    // Build path
    final path = Path();
    final fillPath = Path();
    final zeroY = polarity == 0 ? size.height / 2 : size.height;
    bool first = true;
    for (var i = 0; i < count; i++) {
      final x = positions[i].clamp(0.0, 1.0) * size.width;
      final y = size.height * (0.5 - values[i].clamp(-1.0, 1.0) * 0.5);
      if (first) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    // Close fill path to zero line
    final lastX = positions[count - 1].clamp(0.0, 1.0) * size.width;
    final firstX = positions[0].clamp(0.0, 1.0) * size.width;
    fillPath.lineTo(lastX, zeroY);
    fillPath.lineTo(firstX, zeroY);
    fillPath.close();

    // Fill
    canvas.drawPath(fillPath, Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill);

    // Curve line
    canvas.drawPath(path, Paint()
      ..color = accent.withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Dots at breakpoints
    for (var i = 0; i < count; i++) {
      final x = positions[i].clamp(0.0, 1.0) * size.width;
      final y = size.height * (0.5 - values[i].clamp(-1.0, 1.0) * 0.5);
      canvas.drawCircle(Offset(x, y), 3.0, Paint()
        ..color = accent
        ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_CurvePreviewPainter old) =>
      old.positions != positions || old.values != values || old.polarity != polarity;
}