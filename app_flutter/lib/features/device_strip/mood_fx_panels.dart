import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/device_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'panels/compact_fx_layout.dart';
import 'rotary_knob.dart';

typedef MoodFxParameterChanged = void Function(
    String parameterId, double value);
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
    this.size = DeviceStripMetrics.dynamicsFxKnobSize,
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
  final double size;

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
      onLinkTap: onAutomationLinkTap != null
          ? () => onAutomationLinkTap!(paramId)
          : null,
      onAutomateRequest: onAutomateParameter != null
          ? () => onAutomateParameter!(paramId)
          : null,
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
  double size = DeviceStripMetrics.dynamicsFxKnobSize,
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
    size: size,
  );
}

// ─── Layout helpers ─────────────────────────────────────────

Widget _moodFxSinglePage({
  Widget? preview,
  double? previewHeight,
  double knobRowGap = _kKnobRowGap,
  required List<Widget> rows,
}) {
  return CompactFxPage(
    preview: preview,
    previewHeight: previewHeight,
    rows: rows,
    knobRowGap: knobRowGap,
  );
}

Widget _knobGridRow(List<Widget?> slots) => compactFxKnobGridRow(slots);

Widget _stutterTopRow(Widget hold, Widget rateMode) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: DeviceStripMetrics.dynamicsFxKnobColumnWidth,
        child: Align(alignment: Alignment.topCenter, child: hold),
      ),
      const SizedBox(width: DeviceStripMetrics.dynamicsFxKnobGap),
      SizedBox(
        width: DeviceStripMetrics.dynamicsFxKnobColumnWidth * 2 +
            DeviceStripMetrics.dynamicsFxKnobGap,
        child: rateMode,
      ),
    ],
  );
}

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
    final quantLevels =
        math.max(2, math.min(32, math.pow(2, 1 + bits / 4).round().toInt()));
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
            onParameterChanged: (id, v) =>
                onParameterChanged(id, 0.1 + v * 19.9),
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

// ─── Stutter ─────────────────────────────────────────────────

class StutterFxPanel extends StatelessWidget {
  static const accent = Color(0xFF57D3C4);
  static const containerTabs = <DeviceTabSpec>[];
  static const double designWidth = 216;

  final StutterDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const StutterFxPanel({
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
      previewHeight: 34,
      knobRowGap: 6,
      preview: CustomPaint(
        painter: _StutterPreviewPainter(
          rateNorm: _rateNorm,
          windowNorm: _windowNorm,
          gate: device.gate,
          accent: accent,
        ),
        child: const SizedBox.expand(),
      ),
      rows: [
        _stutterTopRow(
          _StutterHoldButton(
            active: device.trigger >= 0.5,
            automationActive: automatedParams.contains('trigger'),
            linkModeActive: automationLinkActive,
            modulationActive: modulatedParams.contains('trigger'),
            modulationAmount: modulationAmounts['trigger'] ?? 0.0,
            connectModeActive: connectModeLfoId != null,
            accent: accent,
            onTap: () => onParameterChanged(
                'trigger', device.trigger >= 0.5 ? 0.0 : 1.0),
            onAutomationLinkTap: onAutomationLinkTap != null
                ? () => onAutomationLinkTap!('trigger')
                : null,
            onAutomateRequest: onAutomateParameter != null
                ? () => onAutomateParameter!('trigger')
                : null,
            onModulationAssign: onModulationAssign != null
                ? (amount) => onModulationAssign!('trigger', amount)
                : null,
          ),
          _StutterRateModeBox(
            sync: _rateSync,
            rateBeats: _selectedRateBeats,
            rateMs: device.rateMs,
            accent: accent,
            onSyncChanged: (sync) =>
                onParameterChanged('rateSync', sync ? 1.0 : 0.0),
            onRateBeatsChanged: (beats) =>
                onParameterChanged('rateBeats', beats),
            onRateMsChanged: (ms) => onParameterChanged('rateMs', ms),
          ),
        ),
        _StutterShapePanel(
          accent: accent,
          top: [
            _stutterSmallKnob(
              label: 'Cap',
              value: _captureNorm,
              paramId: 'captureMs',
              onParameterChanged: (id, v) =>
                  onParameterChanged(id, _msFromNorm(v, 1, 4000)),
              displayValue: '${device.captureMs.round()} ms',
            ),
            _stutterSmallKnob(
              label: 'Size',
              value: _windowNorm,
              paramId: 'windowMs',
              onParameterChanged: (id, v) =>
                  onParameterChanged(id, _msFromNorm(v, 1, 5000)),
              displayValue: '${device.windowMs.round()} ms',
            ),
          ],
          bottom: [
            _stutterSmallKnob(
              label: 'Pos',
              value: device.position,
              paramId: 'position',
              displayValue: '${(device.position * 100).round()}%',
            ),
            _stutterSmallKnob(
              label: 'Gate',
              value: device.gate,
              paramId: 'gate',
              displayValue: '${(device.gate * 100).round()}%',
            ),
            _stutterSmallKnob(
              label: 'Duck',
              value: device.duck,
              paramId: 'duck',
              displayValue: '${(device.duck * 100).round()}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _stutterSmallKnob({
    required String label,
    required double value,
    required String paramId,
    MoodFxParameterChanged? onParameterChanged,
    required String displayValue,
  }) {
    return _knob(
      label: label,
      value: value,
      paramId: paramId,
      onParameterChanged: onParameterChanged ?? this.onParameterChanged,
      accent: accent,
      modulatedParams: modulatedParams,
      automatedParams: automatedParams,
      modulationAmounts: modulationAmounts,
      connectModeLfoId: connectModeLfoId,
      onModulationAssign: onModulationAssign,
      automationLinkActive: automationLinkActive,
      onAutomationLinkTap: onAutomationLinkTap,
      onAutomateParameter: onAutomateParameter,
      displayValue: displayValue,
      size: DeviceKnobSizes.compact,
    );
  }

  bool get _rateSync => device.rateSync >= 0.5;
  double get _selectedRateBeats => _nearestRateBeats(device.rateBeats);
  double get _rateNorm => _rateSync
      ? _normFromBeats(device.rateBeats)
      : _normFromMs(device.rateMs, 1, 5000);
  double get _windowNorm => _normFromMs(device.windowMs, 1, 5000);
  double get _captureNorm => _normFromMs(device.captureMs, 1, 4000);

  static double _normFromMs(double value, double min, double max) =>
      ((value.clamp(min, max) - min) / (max - min)).clamp(0.0, 1.0);

  static double _msFromNorm(double value, double min, double max) =>
      min + value.clamp(0.0, 1.0) * (max - min);

  static const _rateDivisions = <double>[
    4.0,
    2.0,
    1.0,
    0.5,
    0.25,
    0.125,
    0.0625,
    0.03125,
  ];

  static double _nearestRateBeats(double value) {
    var best = _rateDivisions.first;
    var bestDistance = (value - best).abs();
    for (final candidate in _rateDivisions.skip(1)) {
      final distance = (value - candidate).abs();
      if (distance < bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best;
  }

  static double _normFromBeats(double value) {
    final selected = _nearestRateBeats(value);
    final index = _rateDivisions.indexOf(selected);
    return index < 0 ? 0.5 : index / (_rateDivisions.length - 1);
  }

  static double _beatsFromNorm(double value) {
    final index = (value.clamp(0.0, 1.0) * (_rateDivisions.length - 1)).round();
    return _rateDivisions[index.clamp(0, _rateDivisions.length - 1)];
  }

  static String _labelForBeats(double beats) =>
      switch (_nearestRateBeats(beats)) {
        4.0 => '4/1',
        2.0 => '2/1',
        1.0 => '1/1',
        0.5 => '1/2',
        0.25 => '1/4',
        0.125 => '1/8',
        0.0625 => '1/16',
        _ => '1/32',
      };
}

class StutterFxStrip extends StatelessWidget {
  final StutterDeviceSnapshot device;
  final MoodFxParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final MoodFxModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  const StutterFxStrip({
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
    return StutterFxPanel(
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

class _StutterPreviewPainter extends CustomPainter {
  _StutterPreviewPainter({
    required this.rateNorm,
    required this.windowNorm,
    required this.gate,
    required this.accent,
  });

  final double rateNorm;
  final double windowNorm;
  final double gate;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF101018);
    canvas.drawRect(Offset.zero & size, bg);

    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.75)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = accent.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    final repeats = (3 + (1.0 - rateNorm) * 9).round();
    final gap = size.width / repeats;
    final activeW = (gap * (0.18 + windowNorm * 0.55)).clamp(3.0, gap);
    final activeH = size.height * (0.22 + gate.clamp(0.0, 1.0) * 0.58);
    for (var i = 0; i < repeats; i++) {
      final x = i * gap + gap * 0.12;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - activeH) / 2, activeW, activeH),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _StutterPreviewPainter old) =>
      old.rateNorm != rateNorm ||
      old.windowNorm != windowNorm ||
      old.gate != gate ||
      old.accent != accent;
}

class _StutterShapePanel extends StatelessWidget {
  const _StutterShapePanel({
    required this.accent,
    required this.top,
    required this.bottom,
  });

  final Color accent;
  final List<Widget> top;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: top,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: bottom,
            ),
          ],
        ),
      ),
    );
  }
}

class _StutterRateModeBox extends StatefulWidget {
  const _StutterRateModeBox({
    required this.sync,
    required this.rateBeats,
    required this.rateMs,
    required this.accent,
    required this.onSyncChanged,
    required this.onRateBeatsChanged,
    required this.onRateMsChanged,
  });

  final bool sync;
  final double rateBeats;
  final double rateMs;
  final Color accent;
  final ValueChanged<bool> onSyncChanged;
  final ValueChanged<double> onRateBeatsChanged;
  final ValueChanged<double> onRateMsChanged;

  @override
  State<_StutterRateModeBox> createState() => _StutterRateModeBoxState();
}

class _StutterRateModeBoxState extends State<_StutterRateModeBox> {
  double _dragStartValue = 0.0;
  double _dragStartY = 0.0;

  void _onDragStart(DragStartDetails details) {
    _dragStartValue = widget.rateMs;
    _dragStartY = details.localPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final delta = (_dragStartY - details.localPosition.dy) * 8.0;
    widget.onRateMsChanged((_dragStartValue + delta).clamp(1.0, 5000.0));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = Border.all(color: Colors.white.withValues(alpha: 0.10));
    return SizedBox(
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          borderRadius: BorderRadius.circular(7),
          border: border,
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StutterMiniToggle(
                      label: 'Sync',
                      active: widget.sync,
                      accent: widget.accent,
                      onTap: () => widget.onSyncChanged(true),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _StutterMiniToggle(
                      label: 'Ms',
                      active: !widget.sync,
                      accent: widget.accent,
                      onTap: () => widget.onSyncChanged(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: widget.sync
                    ? PopupMenuButton<double>(
                        tooltip: 'Rate division',
                        padding: EdgeInsets.zero,
                        initialValue: widget.rateBeats,
                        onSelected: widget.onRateBeatsChanged,
                        itemBuilder: (context) => [
                          for (final beats in StutterFxPanel._rateDivisions)
                            PopupMenuItem<double>(
                              value: beats,
                              child: Text(StutterFxPanel._labelForBeats(beats)),
                            ),
                        ],
                        child: _StutterSelectFace(
                          label:
                              StutterFxPanel._labelForBeats(widget.rateBeats),
                          accent: widget.accent,
                        ),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart: _onDragStart,
                        onVerticalDragUpdate: _onDragUpdate,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.045),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.rateMs.round()} ms',
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StutterMiniToggle extends StatelessWidget {
  const _StutterMiniToggle({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              label,
              style: TextStyle(
                color: active ? accent : Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StutterSelectFace extends StatelessWidget {
  const _StutterSelectFace({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.keyboard_arrow_down_rounded, color: accent, size: 14),
        ],
      ),
    );
  }
}

class _StutterHoldButton extends StatefulWidget {
  const _StutterHoldButton({
    required this.active,
    required this.automationActive,
    required this.linkModeActive,
    required this.modulationActive,
    required this.modulationAmount,
    required this.connectModeActive,
    required this.accent,
    required this.onTap,
    this.onAutomationLinkTap,
    this.onAutomateRequest,
    this.onModulationAssign,
  });

  final bool active;
  final bool automationActive;
  final bool linkModeActive;
  final bool modulationActive;
  final double modulationAmount;
  final bool connectModeActive;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onAutomationLinkTap;
  final VoidCallback? onAutomateRequest;
  final ValueChanged<double>? onModulationAssign;

  @override
  State<_StutterHoldButton> createState() => _StutterHoldButtonState();
}

class _StutterHoldButtonState extends State<_StutterHoldButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _assignmentMode = false;
  double _dragStartY = 0.0;
  double _assignmentAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.14, end: 0.42).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (_pulseActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StutterHoldButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.connectModeActive || oldWidget.linkModeActive;
    if (_pulseActive && !wasActive) {
      _pulseController.repeat(reverse: true);
    } else if (!_pulseActive && wasActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _pulseActive => widget.connectModeActive || widget.linkModeActive;

  void _handleTap() {
    if (widget.linkModeActive) {
      return;
    }
    widget.onTap();
  }

  void _handleLongPress() {
    if (widget.linkModeActive) {
      HapticFeedback.mediumImpact();
      widget.onAutomationLinkTap?.call();
    } else if (!widget.connectModeActive) {
      HapticFeedback.mediumImpact();
      widget.onAutomateRequest?.call();
    }
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!widget.connectModeActive) return;
    HapticFeedback.mediumImpact();
    _pulseController.stop();
    _dragStartY = details.localPosition.dy;
    setState(() {
      _assignmentMode = true;
      _assignmentAmount = 0.0;
    });
  }

  void _handleLongPressMove(LongPressMoveUpdateDetails details) {
    if (!_assignmentMode) return;
    final amount = details.localPosition.dy <= _dragStartY ? 1.0 : -1.0;
    setState(() => _assignmentAmount = amount);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_assignmentMode) return;
    widget.onModulationAssign?.call(_assignmentAmount);
    _pulseController.reset();
    if (_pulseActive) {
      _pulseController.repeat(reverse: true);
    }
    setState(() {
      _assignmentMode = false;
      _assignmentAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onLongPress: widget.linkModeActive || !widget.connectModeActive
              ? _handleLongPress
              : null,
          onLongPressStart:
              widget.connectModeActive ? _handleLongPressStart : null,
          onLongPressMoveUpdate:
              widget.connectModeActive ? _handleLongPressMove : null,
          onLongPressEnd: widget.connectModeActive ? _handleLongPressEnd : null,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final pulseAlpha = _pulseActive ? _pulseAnimation.value : 0.0;
              final fill = widget.active
                  ? widget.accent.withValues(alpha: 0.18)
                  : const Color(0xFF12121A);
              final stroke = widget.active
                  ? widget.accent.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.11);
              return SizedBox(
                width: DeviceStripMetrics.dynamicsFxKnobColumnWidth,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      widget.accent.withValues(alpha: pulseAlpha),
                      fill,
                    ),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: stroke, width: 1.2),
                    boxShadow: widget.active
                        ? [
                            BoxShadow(
                              color: widget.accent.withValues(alpha: 0.14),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: widget.active
                                        ? widget.accent
                                        : Colors.white24,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'HOLD',
                                    maxLines: 1,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: widget.active
                                          ? widget.accent
                                          : Colors.white54,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: widget.active
                                    ? widget.accent
                                    : Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.modulationActive || _assignmentMode)
                        Positioned(
                          left: 7,
                          right: 7,
                          bottom: 6,
                          child: _StutterModLine(
                            amount: _assignmentMode
                                ? _assignmentAmount
                                : widget.modulationAmount,
                            color: widget.accent,
                          ),
                        ),
                      if (widget.automationActive)
                        Positioned(
                          right: 5,
                          top: 5,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB48CFF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB48CFF)
                                      .withValues(alpha: 0.65),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Hold',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StutterModLine extends StatelessWidget {
  const _StutterModLine({
    required this.amount,
    required this.color,
  });

  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = amount.abs().clamp(0.0, 1.0);
    return Align(
      alignment: amount >= 0 ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: normalized,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
