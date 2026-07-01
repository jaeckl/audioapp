import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/device_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'panels/compact_fx_layout.dart';
import 'rotary_knob.dart';

typedef MoodFxParameterChanged = void Function(String parameterId, double value);
typedef MoodFxModulationAssign = void Function(String paramId, double amount)?;

const _kKnobRowGap = 10.0;

// ─── Knob wrapper ───────────────────────────────────────────

class _MoodFxKnob extends StatelessWidget {
  const _MoodFxKnob({
    required this.label,
    required this.value,
    required this.paramId,
    required this.accent,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeLfoId,
    required this.onModulationAssign,
    required this.automationLinkActive,
    required this.onAutomationLinkTap,
    required this.onAutomateParameter,
    this.displayValue,
  });

  final String label;
  final double value;
  final String paramId;
  final Color accent;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final String? displayValue;
  final double size = DeviceStripMetrics.dynamicsFxKnobSize;

  @override
  Widget build(BuildContext context) {
    return RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: size,
      displayValue: displayValue,
      accentColor: accent,
      modulationActive: modulatedParams.contains(paramId),
      automationActive: automatedParams.contains(paramId),
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
      connectModeActive: connectModeLfoId != null,
      onModulationAssign: onModulationAssign != null
          ? (amount) => onModulationAssign!(paramId, amount)
          : null,
      linkModeActive: automationLinkActive,
      onLinkTap: onAutomationLinkTap != null ? () => onAutomationLinkTap!(paramId) : null,
      onAutomateRequest:
          onAutomateParameter != null ? () => onAutomateParameter!(paramId) : null,
      onChanged: (v) => onParameterChanged(paramId, v),
    );
  }
}

_MoodFxKnob _knob({
  required String label,
  required double value,
  required String paramId,
  required Color accent,
  required MoodFxParameterChanged onParameterChanged,
  required Set<String> modulatedParams,
  required Set<String> automatedParams,
  required Map<String, double> modulationAmounts,
  required int? connectModeLfoId,
  required MoodFxModulationAssign onModulationAssign,
  required bool automationLinkActive,
  required ValueChanged<String>? onAutomationLinkTap,
  required ValueChanged<String>? onAutomateParameter,
  String? displayValue,
}) {
  return _MoodFxKnob(
    label: label,
    value: value,
    paramId: paramId,
    accent: accent,
    onParameterChanged: onParameterChanged,
    modulatedParams: modulatedParams,
    automatedParams: automatedParams,
    modulationAmounts: modulationAmounts,
    connectModeLfoId: connectModeLfoId,
    onModulationAssign: onModulationAssign,
    automationLinkActive: automationLinkActive,
    onAutomationLinkTap: onAutomationLinkTap,
    onAutomateParameter: onAutomateParameter,
    displayValue: displayValue,
  );
}

// ─── Layout helpers ─────────────────────────────────────────

Widget _moodFxSinglePage({Widget? preview, required List<Widget> rows}) {
  return CompactFxPage(
    preview: preview,
    rows: rows,
    knobRowGap: _kKnobRowGap,
  );
}

Widget _knobGridRow(List<_MoodFxKnob?> slots) => compactFxKnobGridRow(slots);

// ─── Bitcrusher preview painter ──────────────────────────────

class _BitcrusherPreviewPainter extends CustomPainter {
  _BitcrusherPreviewPainter({
    required this.rate,
    required this.bits,
    required this.accent,
  });

  final double rate;
  final double bits;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final cy = h / 2;
    final amp = (h - 8) / 2;

    // Ghost sine — 2 cycles
    final ghostPaint = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final ghostPath = Path();
    for (double x = 0; x <= w; x += 1) {
      final t = x / w * 4 * math.pi;
      final y = cy + math.sin(t) * amp;
      if (x == 0) {
        ghostPath.moveTo(x, y);
      } else {
        ghostPath.lineTo(x, y);
      }
    }
    canvas.drawPath(ghostPath, ghostPaint);

    // Crushed staircase
    final numSamples = (4 + (1 - rate) * 56).round().clamp(2, 60);
    final quantLevels = math.max(2, math.min(32, math.pow(2, 1 + bits / 4).round().toInt()));
    final stepW = w / numSamples;

    final crushedPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    final crushedPath = Path();
    for (int i = 0; i < numSamples; i++) {
      final cx = i * stepW + stepW / 2;
      final t = cx / w * 4 * math.pi;
      final raw = math.sin(t);
      final quantized = (raw * quantLevels / 2).round() / (quantLevels / 2);
      final y = cy + quantized * amp;
      final x0 = i * stepW;
      if (i == 0) {
        crushedPath.moveTo(x0, y);
      } else {
        crushedPath.lineTo(x0, y);
      }
      final x1 = (i + 1) * stepW;
      crushedPath.lineTo(x1, y);
    }
    canvas.drawPath(crushedPath, crushedPaint);
  }

  @override
  bool shouldRepaint(covariant _BitcrusherPreviewPainter old) =>
      old.rate != rate || old.bits != bits || old.accent != accent;
}

// ─── Distortion preview painter ─────────────────────────────

class _DistortionPreviewPainter extends CustomPainter {
  _DistortionPreviewPainter({
    required this.drive,
    required this.accent,
  });

  final double drive;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final cx = w / 2;
    final cy = h / 2;
    final scale = (math.min(cx, cy) - 4);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, cy), Offset(w, cy), gridPaint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, h), gridPaint);

    // Diagonal reference (clean signal)
    final refPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(cx - scale, cy - scale),
      Offset(cx + scale, cy + scale),
      refPaint,
    );

    // Waveshaping curve
    final gain = 0.3 + drive * 4.0;
    final tanhGain = _tanh(gain);

    final curvePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    final curvePath = Path();

    for (double px = 0; px <= w; px += 1) {
      final input = (px / w) * 2 - 1;
      final output = _tanh(input * gain) / tanhGain;
      final py = cy - output * scale;
      if (px == 0) {
        curvePath.moveTo(px, py);
      } else {
        curvePath.lineTo(px, py);
      }
    }
    canvas.drawPath(curvePath, curvePaint);

    // Filled area under curve
    final fillPath = Path();
    fillPath.moveTo(cx - scale, cy);
    for (double px = 0; px <= w; px += 1) {
      final input = (px / w) * 2 - 1;
      final output = _tanh(input * gain) / tanhGain;
      final py = cy - output * scale;
      fillPath.lineTo(px, py);
    }
    fillPath.lineTo(cx + scale, cy);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.45),
            accent.withValues(alpha: 0.04),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  static double _tanh(double x) {
    if (x > 20) return 1;
    if (x < -20) return -1;
    final exp2x = math.exp(2 * x);
    return (exp2x - 1) / (exp2x + 1);
  }

  @override
  bool shouldRepaint(covariant _DistortionPreviewPainter old) =>
      old.drive != drive || old.accent != accent;
}

// ─── Tremolo preview painter ────────────────────────────────

class _TremoloPreviewPainter extends CustomPainter {
  _TremoloPreviewPainter({
    required this.depth,
    required this.shape,
    required this.accent,
  });

  final double depth;
  final double shape;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final cy = h / 2;
    final amp = (h - 12) / 2;
    const lfoCycles = 2.0;

    // LFO envelope guide (dashed line at top boundary)
    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final guidePath = Path();
    for (double x = 0; x <= w; x += 1) {
      final t = x / w * lfoCycles;
      final lfo = _lfoValue(t, shape);
      final env = 1.0 - depth + depth * lfo;
      final ey = cy - env * amp;
      if (x == 0) {
        guidePath.moveTo(x, ey);
      } else {
        guidePath.lineTo(x, ey);
      }
    }
    // Draw dashed
    final metrics = guidePath.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + 3).clamp(0.0, metric.length);
        final seg = metric.extractPath(dist, end);
        canvas.drawPath(seg, guidePaint);
        dist += 7;
      }
    }

    // Filled modulated-carrier area
    final fillPath = Path();
    fillPath.moveTo(0, cy);
    for (double x = 0; x <= w; x += 1) {
      final t = x / w * lfoCycles;
      final lfo = _lfoValue(t, shape);
      final env = 1.0 - depth + depth * lfo;
      final carrier = math.sin(2 * math.pi * t * 3);
      final y = cy - carrier * env * amp;
      fillPath.lineTo(x, y);
    }
    // Mirror back along zero crossings – draw bottom edge
    for (double x = w; x >= 0; x -= 1) {
      final t = x / w * lfoCycles;
      final lfo = _lfoValue(t, shape);
      final env = 1.0 - depth + depth * lfo;
      final carrier = math.sin(2 * math.pi * t * 3);
      final y = cy + carrier * env * amp;
      fillPath.lineTo(x, y);
    }
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.5),
            accent.withValues(alpha: 0.06),
          ],
        ).createShader(Offset.zero & size),
    );

    // Carrier outline for clarity
    final carrierPaint = Paint()
      ..color = accent.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final carrierPath = Path();
    carrierPath.moveTo(0, cy);
    for (double x = 0; x <= w; x += 1) {
      final t = x / w * lfoCycles;
      final lfo = _lfoValue(t, shape);
      final env = 1.0 - depth + depth * lfo;
      final carrier = math.sin(2 * math.pi * t * 3);
      final y = cy - carrier * env * amp;
      carrierPath.lineTo(x, y);
    }
    canvas.drawPath(carrierPath, carrierPaint);
  }

  static double _lfoValue(double cycles, double shape) {
    if (shape < 0.5) {
      return 0.5 + 0.5 * math.sin(2 * math.pi * cycles);
    }
    return (math.sin(2 * math.pi * cycles) >= 0) ? 1.0 : 0.0;
  }

  @override
  bool shouldRepaint(covariant _TremoloPreviewPainter old) =>
      old.depth != depth || old.shape != shape || old.accent != accent;
}

// ─── Bitcrusher ──────────────────────────────────────────────

class BitcrusherFxPanel extends StatelessWidget {
  static const accent = Color(0xFF7B6CF6);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 216;

  final BitcrusherDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const BitcrusherFxPanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  @override
  Widget build(BuildContext context) {
    return _moodFxSinglePage(
      preview: CustomPaint(
        painter: _BitcrusherPreviewPainter(
          rate: device.bcRate,
          bits: device.bcBits,
          accent: accent,
        ),
        child: const SizedBox.expand(),
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Rate',
            value: device.bcRate,
            paramId: 'bcRate',
            onParameterChanged: onParameterChanged,
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${(device.bcRate * 100).round()}%',
          ),
          _knob(
            label: 'Bits',
            value: _bcBitsNorm,
            paramId: 'bcBits',
            onParameterChanged: (id, v) => onParameterChanged(id, 1 + v * 15),
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${device.bcBits.round()} bit',
          ),
          null,
        ]),
      ],
    );
  }

  double get _bcBitsNorm => ((device.bcBits - 1) / 15).clamp(0.0, 1.0);
}

class BitcrusherFxStrip extends StatelessWidget {
  final BitcrusherDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const BitcrusherFxStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  @override
  Widget build(BuildContext context) {
    return BitcrusherFxPanel(
      device: device,
      onParameterChanged: onParameterChanged,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
    );
  }
}

// ─── Distortion ─────────────────────────────────────────────

class DistortionFxPanel extends StatelessWidget {
  static const accent = Color(0xFFE85D4B);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 216;

  final DistortionDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const DistortionFxPanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  @override
  Widget build(BuildContext context) {
    return _moodFxSinglePage(
      preview: CustomPaint(
        painter: _DistortionPreviewPainter(
          drive: device.distDrive,
          accent: accent,
        ),
        child: const SizedBox.expand(),
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Drive',
            value: device.distDrive,
            paramId: 'distDrive',
            onParameterChanged: onParameterChanged,
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${(device.distDrive * 100).round()}%',
          ),
          _knob(
            label: 'Tone',
            value: device.distTone,
            paramId: 'distTone',
            onParameterChanged: onParameterChanged,
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${(device.distTone * 100).round()}%',
          ),
          null,
        ]),
      ],
    );
  }
}

class DistortionFxStrip extends StatelessWidget {
  final DistortionDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const DistortionFxStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  @override
  Widget build(BuildContext context) {
    return DistortionFxPanel(
      device: device,
      onParameterChanged: onParameterChanged,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
    );
  }
}

// ─── Tremolo ────────────────────────────────────────────────

class TremoloFxPanel extends StatelessWidget {
  static const accent = Color(0xFF4ADE80);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 216;

  final TremoloDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const TremoloFxPanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  @override
  Widget build(BuildContext context) {
    return _moodFxSinglePage(
      preview: CustomPaint(
        painter: _TremoloPreviewPainter(
          depth: device.tremDepth,
          shape: device.tremShape,
          accent: accent,
        ),
        child: const SizedBox.expand(),
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Depth',
            value: device.tremDepth,
            paramId: 'tremDepth',
            onParameterChanged: onParameterChanged,
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${(device.tremDepth * 100).round()}%',
          ),
          _knob(
            label: 'Rate',
            value: _tremRateNorm,
            paramId: 'tremRate',
            onParameterChanged: (id, v) => onParameterChanged(id, 0.1 + v * 19.9),
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${device.tremRate.toStringAsFixed(1)} Hz',
          ),
          _knob(
            label: 'Shape',
            value: device.tremShape,
            paramId: 'tremShape',
            onParameterChanged: onParameterChanged,
            accent: accent,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: device.tremShape < 0.5 ? 'Sine' : 'Square',
          ),
        ]),
      ],
    );
  }

  double get _tremRateNorm => ((device.tremRate - 0.1) / 19.9).clamp(0.0, 1.0);
}

class TremoloFxStrip extends StatelessWidget {
  final TremoloDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const TremoloFxStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  @override
  Widget build(BuildContext context) {
    return TremoloFxPanel(
      device: device,
      onParameterChanged: onParameterChanged,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
    );
  }
}
