import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/device_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

part 'resonator_bank_panel_resonator_bank_preview_painter.dart';

typedef ResonatorParameterChanged = void Function(
    String parameterId, double value);
typedef ResonatorModulationAssign = void Function(
    String paramId, double amount)?;

class ResonatorBankPanel extends StatelessWidget {
  static const registeredDeviceTypes = ['resonator_bank'];
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
