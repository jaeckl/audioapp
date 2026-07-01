import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_tab_bar.dart';
import 'dynamics_envelope_preview.dart';
import 'panels/compact_fx_layout.dart';
import 'rotary_knob.dart';

enum GateDeviceTab { detect, time, range }
enum CompressorDeviceTab { comp, time, gain }
enum ExpanderDeviceTab { expand, time, range }
enum LimiterDeviceTab { ceiling, time, gain }

typedef DynamicsParameterChanged = void Function(String parameterId, double value);
typedef DynamicsModulationAssign = void Function(String paramId, double amount)?;

const double _dynamicsKnobRowGap = 10;

class _DynamicsKnob extends StatelessWidget {
  const _DynamicsKnob({
    required this.label,
    required this.value,
    required this.paramId,
    required this.accent,
    required this.onParameterChanged,
    required this.modulatedParams,
    required this.automatedParams,
    required this.modulationAmounts,
    required this.connectModeLfoId,
    required this.deviceId,
    required this.lfos,
    required this.modEdges,
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
  final DynamicsParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final String deviceId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
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
      polarityParamId: paramId,
      deviceId: deviceId,
      lfos: lfos,
      modEdges: modEdges,
      connectModeLfoId: connectModeLfoId,
      connectModeActive: connectModeLfoId != null,
      onModulationAssign:
          onModulationAssign != null ? (amount) => onModulationAssign!(paramId, amount) : null,
      linkModeActive: automationLinkActive,
      onLinkTap: onAutomationLinkTap != null ? () => onAutomationLinkTap!(paramId) : null,
      onAutomateRequest:
          onAutomateParameter != null ? () => onAutomateParameter!(paramId) : null,
      onChanged: (v) => onParameterChanged(paramId, v),
    );
  }
}

_DynamicsKnob _knob({
  required String label,
  required double value,
  required String paramId,
  required Color accent,
  required DynamicsParameterChanged onParameterChanged,
  required Set<String> modulatedParams,
  required Set<String> automatedParams,
  required Map<String, double> modulationAmounts,
  required int? connectModeLfoId,
  required String deviceId,
  required List<LfoSnapshot> lfos,
  required List<ModulationEdgeSnapshot> modEdges,
  required DynamicsModulationAssign onModulationAssign,
  required bool automationLinkActive,
  required ValueChanged<String>? onAutomationLinkTap,
  required ValueChanged<String>? onAutomateParameter,
  String? displayValue,
}) {
  return _DynamicsKnob(
    label: label,
    value: value,
    paramId: paramId,
    accent: accent,
    onParameterChanged: onParameterChanged,
    modulatedParams: modulatedParams,
            automatedParams: automatedParams,
    modulationAmounts: modulationAmounts,
    connectModeLfoId: connectModeLfoId,
    deviceId: deviceId,
    lfos: lfos,
    modEdges: modEdges,
    onModulationAssign: onModulationAssign,
    automationLinkActive: automationLinkActive,
    onAutomationLinkTap: onAutomationLinkTap,
    onAutomateParameter: onAutomateParameter,
    displayValue: displayValue,
  );
}

Widget _dynamicsSinglePage({
  required Widget preview,
  required List<Widget> rows,
}) {
  return CompactFxPage(
    preview: preview,
    expandPreview: true,
    rows: rows,
    knobRowGap: _dynamicsKnobRowGap,
  );
}

Widget _knobGridRow(List<_DynamicsKnob?> slots) => compactFxKnobGridRow(slots);

class GateDevicePanel extends StatelessWidget {
  const GateDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFF6EC9A8);
  static const containerTabs = <DeviceTabSpec>[];

  /// Gate — compact dynamics FX card.
  static const double designWidth = 216;

  final GateDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final GateDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return _dynamicsSinglePage(
      preview: DynamicsEnvelopePreview(
        threshold: device.gateThreshold,
        accent: accent,
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Threshold',
            value: device.gateThreshold,
            paramId: 'gateThreshold',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsThresholdLabel(device.gateThreshold),
          ),
          _knob(
            label: 'Attack',
            value: device.gateAttack,
            paramId: 'gateAttack',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.gateAttack),
          ),
          _knob(
            label: 'Release',
            value: device.gateRelease,
            paramId: 'gateRelease',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.gateRelease),
          ),
        ]),
        _knobGridRow([
          _knob(
            label: 'Hold',
            value: device.gateHold,
            paramId: 'gateHold',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsHoldLabel(device.gateHold),
          ),
          _knob(
            label: 'Floor',
            value: device.gateRange,
            paramId: 'gateRange',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsRangeLabel(device.gateRange),
          ),
          null,
        ]),
      ],
    );
  }
}

class GateDeviceStrip extends StatelessWidget {
  const GateDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });
  final GateDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final GateDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => GateDevicePanel(
        device: device,
        onParameterChanged: onParameterChanged,
        selectedTab: selectedTab,
        modulatedParams: modulatedParams,
            automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        lfos: lfos,
        modEdges: modEdges,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      );
}

class CompressorDevicePanel extends StatelessWidget {
  const CompressorDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });
  static const accent = Color(0xFFE8A54B);
  static const containerTabs = <DeviceTabSpec>[];

  /// Compressor — compact dynamics FX card.
  static const double designWidth = 216;
  final CompressorDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final CompressorDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return _dynamicsSinglePage(
      preview: DynamicsEnvelopePreview(
        threshold: device.compThreshold,
        ratio: device.compRatio,
        accent: accent,
        mode: DynamicsPreviewMode.compressor,
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Threshold',
            value: device.compThreshold,
            paramId: 'compThreshold',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsThresholdLabel(device.compThreshold),
          ),
          _knob(
            label: 'Ratio',
            value: device.compRatio,
            paramId: 'compRatio',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsRatioLabel(device.compRatio),
          ),
          _knob(
            label: 'Knee',
            value: device.compKnee,
            paramId: 'compKnee',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${(device.compKnee * 12).round()} dB',
          ),
        ]),
        _knobGridRow([
          _knob(
            label: 'Attack',
            value: device.compAttack,
            paramId: 'compAttack',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.compAttack),
          ),
          _knob(
            label: 'Release',
            value: device.compRelease,
            paramId: 'compRelease',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.compRelease),
          ),
          _knob(
            label: 'Makeup',
            value: device.compMakeup,
            paramId: 'compMakeup',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsMakeupLabel(device.compMakeup),
          ),
        ]),
      ],
    );
  }
}

class CompressorDeviceStrip extends StatelessWidget {
  const CompressorDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });
  final CompressorDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final CompressorDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => CompressorDevicePanel(
        device: device,
        onParameterChanged: onParameterChanged,
        selectedTab: selectedTab,
        modulatedParams: modulatedParams,
            automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        lfos: lfos,
        modEdges: modEdges,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      );
}

class ExpanderDevicePanel extends StatelessWidget {
  const ExpanderDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });
  static const accent = Color(0xFF9AD4E8);
  static const containerTabs = <DeviceTabSpec>[];

  /// Expander — compact dynamics FX card.
  static const double designWidth = 216;
  final ExpanderDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final ExpanderDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return _dynamicsSinglePage(
      preview: DynamicsEnvelopePreview(
        threshold: device.expandThreshold,
        ratio: device.expandRatio,
        accent: accent,
        mode: DynamicsPreviewMode.expander,
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Threshold',
            value: device.expandThreshold,
            paramId: 'expandThreshold',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsThresholdLabel(device.expandThreshold),
          ),
          _knob(
            label: 'Ratio',
            value: device.expandRatio,
            paramId: 'expandRatio',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsRatioLabel(device.expandRatio, expander: true),
          ),
          _knob(
            label: 'Attack',
            value: device.expandAttack,
            paramId: 'expandAttack',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.expandAttack),
          ),
        ]),
        _knobGridRow([
          _knob(
            label: 'Release',
            value: device.expandRelease,
            paramId: 'expandRelease',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.expandRelease),
          ),
          _knob(
            label: 'Floor',
            value: device.expandRange,
            paramId: 'expandRange',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsRangeLabel(device.expandRange),
          ),
          null,
        ]),
      ],
    );
  }
}

class ExpanderDeviceStrip extends StatelessWidget {
  const ExpanderDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });
  final ExpanderDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final ExpanderDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => ExpanderDevicePanel(
        device: device,
        onParameterChanged: onParameterChanged,
        selectedTab: selectedTab,
        modulatedParams: modulatedParams,
            automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        lfos: lfos,
        modEdges: modEdges,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      );
}

class LimiterDevicePanel extends StatelessWidget {
  const LimiterDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });
  static const accent = Color(0xFFE85D4B);
  static const containerTabs = <DeviceTabSpec>[];

  /// Limiter — compact dynamics FX card.
  static const double designWidth = 216;
  final LimiterDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final LimiterDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    return _dynamicsSinglePage(
      preview: DynamicsEnvelopePreview(
        threshold: device.limitCeiling,
        ceiling: device.limitCeiling,
        accent: accent,
        mode: DynamicsPreviewMode.limiter,
      ),
      rows: [
        _knobGridRow([
          _knob(
            label: 'Ceiling',
            value: device.limitCeiling,
            paramId: 'limitCeiling',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsCeilingLabel(device.limitCeiling),
          ),
          _knob(
            label: 'Attack',
            value: device.limitAttack,
            paramId: 'limitAttack',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.limitAttack),
          ),
          _knob(
            label: 'Release',
            value: device.limitRelease,
            paramId: 'limitRelease',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsTimeLabel(device.limitRelease),
          ),
        ]),
        _knobGridRow([
          _knob(
            label: 'Knee',
            value: device.limitKnee,
            paramId: 'limitKnee',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: '${(device.limitKnee * 12).round()} dB',
          ),
          _knob(
            label: 'Drive',
            value: device.limitDrive,
            paramId: 'limitDrive',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsDriveLabel(device.limitDrive),
          ),
          _knob(
            label: 'Makeup',
            value: device.limitMakeup,
            paramId: 'limitMakeup',
            accent: accent,
            onParameterChanged: onParameterChanged,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            connectModeLfoId: connectModeLfoId,
            deviceId: device.id,
            lfos: lfos,
            modEdges: modEdges,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            displayValue: dynamicsMakeupLabel(device.limitMakeup),
          ),
        ]),
      ],
    );
  }
}

class LimiterDeviceStrip extends StatelessWidget {
  const LimiterDeviceStrip({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.lfos = const [],
    this.modEdges = const [],
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });
  final LimiterDeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final LimiterDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => LimiterDevicePanel(
        device: device,
        onParameterChanged: onParameterChanged,
        selectedTab: selectedTab,
        modulatedParams: modulatedParams,
            automatedParams: automatedParams,
        modulationAmounts: modulationAmounts,
        lfos: lfos,
        modEdges: modEdges,
        connectModeLfoId: connectModeLfoId,
        onModulationAssign: onModulationAssign,
        automationLinkActive: automationLinkActive,
        onAutomationLinkTap: onAutomationLinkTap,
        onAutomateParameter: onAutomateParameter,
      );
}
