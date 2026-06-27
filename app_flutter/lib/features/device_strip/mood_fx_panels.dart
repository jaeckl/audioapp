import 'package:flutter/material.dart';

import '../../bridge/device_snapshot.dart';
import 'device_tab_bar.dart';
import 'device_strip_theme.dart';
import 'device_strip_metrics.dart';
import 'rotary_knob.dart';

// ─── Typedefs ────────────────────────────────────────────────────────────────

typedef MoodFxParameterChanged = void Function(String parameterId, double value);
typedef MoodFxModulationAssign = void Function(String paramId, double amount)?;

// ─── Helpers ──────────────────────────────────────────────────────────────────

const _kPanelColor = Color(0xFF16161E);

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
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
      connectModeActive: connectModeLfoId != null,
      onModulationAssign: onModulationAssign != null
          ? (amount) => onModulationAssign!(paramId, amount)
          : null,
      linkModeActive: automationLinkActive && automatedParams.contains(paramId),
      onLinkTap: onAutomationLinkTap != null ? () => onAutomationLinkTap!(paramId) : null,
      onAutomateRequest: onAutomateParameter != null
          ? () => onAutomateParameter!(paramId)
          : null,
      onChanged: (v) => onParameterChanged(paramId, v),
    );
  }
}

Widget _knobGridRow(List<Widget> knobs) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    decoration: BoxDecoration(
      color: _kPanelColor,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: knobs,
    ),
  );
}

Widget _moodFxSinglePage({required List<Widget> rows}) {
  return Padding(
    padding: const EdgeInsets.all(6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) ...[
          if (rows.indexOf(row) > 0) const SizedBox(height: 6),
          row,
        ],
      ],
    ),
  );
}

// ─── Bitcrusher ───────────────────────────────────────────────────────────────

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
    return _moodFxSinglePage(rows: [
      _knobGridRow([
        _MoodFxKnob(label: 'Rate', value: device.bcRate, paramId: 'bcRate',
          onParameterChanged: onParameterChanged, accent: accent,
          modulatedParams: modulatedParams, automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${(device.bcRate * 100).round()}%'),
        _MoodFxKnob(label: 'Bits', value: _bcBitsNorm, paramId: 'bcBits',
          onParameterChanged: (id, v) => onParameterChanged(id, 1 + v * 15), accent: accent,
          modulatedParams: modulatedParams, automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${device.bcBits.round()} bit'),
      ]),
      _knobGridRow([
        _MoodFxKnob(label: 'Mix', value: device.bcMix, paramId: 'bcMix',
          onParameterChanged: onParameterChanged, accent: accent,
          modulatedParams: modulatedParams, automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${(device.bcMix * 100).round()}%'),
      ]),
    ]);
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

// ─── Distortion ──────────────────────────────────────────────────────────────

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
    return _moodFxSinglePage(rows: [
      _knobGridRow([
        _MoodFxKnob(label: 'Drive', value: device.distDrive, paramId: 'distDrive',
          onParameterChanged: onParameterChanged, accent: accent,
          modulatedParams: modulatedParams, automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${(device.distDrive * 100).round()}%'),
        _MoodFxKnob(label: 'Tone', value: device.distTone, paramId: 'distTone',
          onParameterChanged: onParameterChanged, accent: accent,
          modulatedParams: modulatedParams, automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${(device.distTone * 100).round()}%'),
      ]),
      _knobGridRow([
        _MoodFxKnob(label: 'Mix', value: device.distMix, paramId: 'distMix',
          onParameterChanged: onParameterChanged, accent: accent,
          modulatedParams: modulatedParams, automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${(device.distMix * 100).round()}%'),
      ]),
    ]);
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

// ─── Tremolo ─────────────────────────────────────────────────────────────────

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
    return _moodFxSinglePage(rows: [
      _knobGridRow([
        _MoodFxKnob(label: 'Depth', value: device.tremDepth, paramId: 'tremDepth',
          onParameterChanged: onParameterChanged, accent: accent,
          modulatedParams: modulatedParams, automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${(device.tremDepth * 100).round()}%'),
        _MoodFxKnob(label: 'Rate', value: _tremRateNorm, paramId: 'tremRate',
          onParameterChanged: (id, v) => onParameterChanged(id, 0.1 + v * 19.9), accent: accent,
          modulatedParams: modulatedParams, automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: '${device.tremRate.toStringAsFixed(1)} Hz'),
      ]),
      _knobGridRow([
        _MoodFxKnob(label: 'Shape', value: device.tremShape, paramId: 'tremShape',
          onParameterChanged: onParameterChanged, accent: accent,
          modulatedParams: modulatedParams, automatedParams: automatedParams,
          modulationAmounts: modulationAmounts,
          connectModeLfoId: connectModeLfoId,
          onModulationAssign: onModulationAssign,
          automationLinkActive: automationLinkActive,
          onAutomationLinkTap: onAutomationLinkTap,
          onAutomateParameter: onAutomateParameter,
          displayValue: device.tremShape < 0.5 ? 'Sine' : 'Square'),
      ]),
    ]);
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