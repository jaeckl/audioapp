import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/device_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

typedef ResonatorParameterChanged = void Function(
    String parameterId, double value);
typedef ResonatorModulationAssign = void Function(
    String paramId, double amount)?;

class ResonatorBankPanel extends StatelessWidget {
  const ResonatorBankPanel({
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

  static const accent = Color(0xFFFFB454);
  static const double designWidth = 304;
  static const containerTabs = <DeviceTabSpec>[];

  final ResonatorBankDeviceSnapshot device;
  final ResonatorParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final ResonatorModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF12121A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: CustomPaint(
                painter: ResonatorBankPreviewPainter(
                  root: device.resRoot,
                  spread: device.resSpread,
                  decay: device.resDecay,
                  damping: device.resDamping,
                  color: device.resColor,
                  width: device.resWidth,
                  accent: accent,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _knob('Root', 'resRoot', device.resRoot,
                  _rootLabel(device.resRoot)),
              _knob('Spread', 'resSpread', device.resSpread,
                  (0.5 + device.resSpread).toStringAsFixed(2)),
              _knob('Decay', 'resDecay', device.resDecay,
                  _decayLabel(device.resDecay)),
              _knob('Damping', 'resDamping', device.resDamping,
                  _percent(device.resDamping)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _knob('Color', 'resColor', device.resColor,
                  _signedColor(device.resColor)),
              _knob('Width', 'resWidth', device.resWidth,
                  '${(device.resWidth * 200).round()}%'),
              _knob('Mix', 'resMix', device.resMix, _percent(device.resMix)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _knob(
      String label, String parameterId, double value, String displayValue) {
    return RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: DeviceStripMetrics.dynamicsFxKnobSize,
      displayValue: displayValue,
      accentColor: accent,
      modulationActive: modulatedParams.contains(parameterId),
      automationActive: automatedParams.contains(parameterId),
      modulationAmount: modulationAmounts[parameterId] ?? 0,
      connectModeActive: connectModeLfoId != null,
      onModulationAssign: onModulationAssign == null
          ? null
          : (amount) => onModulationAssign!(parameterId, amount),
      linkModeActive: automationLinkActive,
      onLinkTap: onAutomationLinkTap == null
          ? null
          : () => onAutomationLinkTap!(parameterId),
      onAutomateRequest: onAutomateParameter == null
          ? null
          : () => onAutomateParameter!(parameterId),
      onChanged: (value) => onParameterChanged(parameterId, value),
    );
  }

  static String _percent(double value) => '${(value * 100).round()}%';

  static String _decayLabel(double value) {
    final seconds = 0.08 * math.pow(150, value.clamp(0.0, 1.0));
    return seconds < 1
        ? '${(seconds * 1000).round()} ms'
        : '${seconds.toStringAsFixed(1)} s';
  }

  static String _signedColor(double value) {
    final db = (value - 0.5) * 24;
    return '${db >= 0 ? '+' : ''}${db.toStringAsFixed(1)} dB/oct';
  }

  static String _rootLabel(double value) {
    const names = [
      'C',
      'C♯',
      'D',
      'D♯',
      'E',
      'F',
      'F♯',
      'G',
      'G♯',
      'A',
      'A♯',
      'B'
    ];
    final midi = (24 + value.clamp(0.0, 1.0) * 72).round();
    return '${names[midi % 12]}${midi ~/ 12 - 1}';
  }
}

class ResonatorBankPreviewPainter extends CustomPainter {
  const ResonatorBankPreviewPainter({
    required this.root,
    required this.spread,
    required this.decay,
    required this.damping,
    required this.color,
    required this.width,
    required this.accent,
  });

  final double root;
  final double spread;
  final double decay;
  final double damping;
  final double color;
  final double width;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Colors.white.withValues(alpha: 0.055);
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final rootMidi = 24 + root.clamp(0.0, 1.0) * 72;
    final rootHz = 440 * math.pow(2, (rootMidi - 69) / 12);
    final exponent = 0.5 + spread.clamp(0.0, 1.0);
    for (var band = 0; band < 6; band++) {
      final ratio = math.pow(band + 1, exponent).toDouble();
      final hz = (rootHz * ratio).clamp(20.0, 20000.0);
      final x = ((math.log(hz / 20) / math.log(1000)) * size.width)
          .clamp(4.0, size.width - 4);
      final octave = math.log(math.max(ratio, 1)) / math.ln2;
      final colorGain =
          math.pow(10, ((color - 0.5) * 24 * octave) / 20).toDouble();
      final damp = math.exp(-damping * octave * 1.4);
      final peak = (0.32 + decay * 0.55) * damp * colorGain.clamp(0.28, 2.2);
      final height = (size.height * peak).clamp(8.0, size.height * 0.88);
      final stereo = (band.isEven ? -1 : 1) * width;
      final bandColor = Color.lerp(
          accent,
          stereo < 0 ? Colors.cyanAccent : Colors.pinkAccent,
          stereo.abs().clamp(0.0, 1.0) * 0.28)!;
      final glow = Paint()
        ..color = bandColor.withValues(alpha: 0.14)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      final line = Paint()
        ..color = bandColor.withValues(alpha: 0.88)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, size.height - 7),
          Offset(x, size.height - 7 - height), glow);
      canvas.drawLine(Offset(x, size.height - 7),
          Offset(x, size.height - 7 - height), line);
      canvas.drawCircle(
          Offset(x, size.height - 7 - height), 2.8, Paint()..color = bandColor);
    }
  }

  @override
  bool shouldRepaint(covariant ResonatorBankPreviewPainter oldDelegate) =>
      root != oldDelegate.root ||
      spread != oldDelegate.spread ||
      decay != oldDelegate.decay ||
      damping != oldDelegate.damping ||
      color != oldDelegate.color ||
      width != oldDelegate.width;
}
