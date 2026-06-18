import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_tab_bar.dart';
import 'dynamics_envelope_preview.dart';
import 'rotary_knob.dart';

enum GateDeviceTab { detect, time, range }
enum CompressorDeviceTab { comp, time, gain }
enum ExpanderDeviceTab { expand, time, range }
enum LimiterDeviceTab { ceiling, time, gain }

typedef DynamicsParameterChanged = void Function(String parameterId, double value);
typedef DynamicsModulationAssign = void Function(String paramId, double amount)?;

class _DynamicsKnob extends StatelessWidget {
  const _DynamicsKnob({
    required this.label,
    required this.value,
    required this.paramId,
    required this.accent,
    required this.onParameterChanged,
    required this.modulatedParams,
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
  final DynamicsParameterChanged onParameterChanged;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  final String? displayValue;

  @override
  Widget build(BuildContext context) {
    return RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: DeviceKnobSizes.strip,
      displayValue: displayValue,
      accentColor: accent,
      modulationActive: modulatedParams.contains(paramId),
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
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

Widget _previewBox(Widget child) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF0E0E14),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(6), child: child),
  );
}

_DynamicsKnob _knob({
  required String label,
  required double value,
  required String paramId,
  required Color accent,
  required DynamicsParameterChanged onParameterChanged,
  required Set<String> modulatedParams,
  required Map<String, double> modulationAmounts,
  required int? connectModeLfoId,
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
    modulationAmounts: modulationAmounts,
    connectModeLfoId: connectModeLfoId,
    onModulationAssign: onModulationAssign,
    automationLinkActive: automationLinkActive,
    onAutomationLinkTap: onAutomationLinkTap,
    onAutomateParameter: onAutomateParameter,
    displayValue: displayValue,
  );
}

class GateDevicePanel extends StatelessWidget {
  const GateDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.selectedTab,
    this.modulatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  static const accent = Color(0xFF6EC9A8);
  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Detect', icon: Icons.graphic_eq),
    DeviceTabSpec(label: 'Time', icon: Icons.timer),
    DeviceTabSpec(label: 'Range', icon: Icons.vertical_align_bottom),
  ];

  final DeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final GateDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final tab = selectedTab ?? GateDeviceTab.detect;
    return switch (tab) {
      GateDeviceTab.detect => Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: _previewBox(DynamicsEnvelopePreview(
                  threshold: device.gateThreshold,
                  accent: accent,
                )),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _knob(
                      label: 'Threshold',
                      value: device.gateThreshold,
                      paramId: 'gateThreshold',
                      accent: accent,
                      onParameterChanged: onParameterChanged,
                      modulatedParams: modulatedParams,
                      modulationAmounts: modulationAmounts,
                      connectModeLfoId: connectModeLfoId,
                      onModulationAssign: onModulationAssign,
                      automationLinkActive: automationLinkActive,
                      onAutomationLinkTap: onAutomationLinkTap,
                      onAutomateParameter: onAutomateParameter,
                      displayValue: dynamicsThresholdLabel(device.gateThreshold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      GateDeviceTab.time => Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _knob(label: 'Attack', value: device.gateAttack, paramId: 'gateAttack', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsTimeLabel(device.gateAttack)),
              _knob(label: 'Release', value: device.gateRelease, paramId: 'gateRelease', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsTimeLabel(device.gateRelease)),
              _knob(label: 'Hold', value: device.gateHold, paramId: 'gateHold', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsHoldLabel(device.gateHold)),
            ],
          ),
        ),
      GateDeviceTab.range => Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _knob(label: 'Floor', value: device.gateRange, paramId: 'gateRange', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsRangeLabel(device.gateRange)),
            ],
          ),
        ),
    };
  }
}

class GateDeviceStrip extends StatelessWidget {
  const GateDeviceStrip({super.key, required this.device, required this.onParameterChanged, this.selectedTab, this.modulatedParams = const {}, this.modulationAmounts = const {}, this.connectModeLfoId, this.onModulationAssign, this.automationLinkActive = false, this.onAutomationLinkTap, this.onAutomateParameter});
  final DeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final GateDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => GateDevicePanel(device: device, onParameterChanged: onParameterChanged, selectedTab: selectedTab, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter);
}

class CompressorDevicePanel extends StatelessWidget {
  const CompressorDevicePanel({super.key, required this.device, required this.onParameterChanged, this.selectedTab, this.modulatedParams = const {}, this.modulationAmounts = const {}, this.connectModeLfoId, this.onModulationAssign, this.automationLinkActive = false, this.onAutomationLinkTap, this.onAutomateParameter});
  static const accent = Color(0xFFE8A54B);
  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Comp', icon: Icons.compress),
    DeviceTabSpec(label: 'Time', icon: Icons.timer),
    DeviceTabSpec(label: 'Gain', icon: Icons.show_chart),
  ];
  final DeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final CompressorDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final tab = selectedTab ?? CompressorDeviceTab.comp;
    return switch (tab) {
      CompressorDeviceTab.comp => Padding(padding: const EdgeInsets.all(8), child: Column(children: [Expanded(flex: 3, child: _previewBox(DynamicsEnvelopePreview(threshold: device.compThreshold, ratio: device.compRatio, accent: accent, mode: DynamicsPreviewMode.compressor))), const SizedBox(height: 8), Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_knob(label: 'Threshold', value: device.compThreshold, paramId: 'compThreshold', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsThresholdLabel(device.compThreshold)), _knob(label: 'Ratio', value: device.compRatio, paramId: 'compRatio', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsRatioLabel(device.compRatio)), _knob(label: 'Knee', value: device.compKnee, paramId: 'compKnee', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: '${(device.compKnee * 12).round()} dB')]))])),
      CompressorDeviceTab.time => Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_knob(label: 'Attack', value: device.compAttack, paramId: 'compAttack', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsTimeLabel(device.compAttack)), _knob(label: 'Release', value: device.compRelease, paramId: 'compRelease', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsTimeLabel(device.compRelease))])),
      CompressorDeviceTab.gain => Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [_knob(label: 'Makeup', value: device.compMakeup, paramId: 'compMakeup', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsMakeupLabel(device.compMakeup))])),
    };
  }
}

class CompressorDeviceStrip extends StatelessWidget {
  const CompressorDeviceStrip({super.key, required this.device, required this.onParameterChanged, this.selectedTab, this.modulatedParams = const {}, this.modulationAmounts = const {}, this.connectModeLfoId, this.onModulationAssign, this.automationLinkActive = false, this.onAutomationLinkTap, this.onAutomateParameter});
  final DeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final CompressorDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => CompressorDevicePanel(device: device, onParameterChanged: onParameterChanged, selectedTab: selectedTab, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter);
}

class ExpanderDevicePanel extends StatelessWidget {
  const ExpanderDevicePanel({super.key, required this.device, required this.onParameterChanged, this.selectedTab, this.modulatedParams = const {}, this.modulationAmounts = const {}, this.connectModeLfoId, this.onModulationAssign, this.automationLinkActive = false, this.onAutomationLinkTap, this.onAutomateParameter});
  static const accent = Color(0xFF9AD4E8);
  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Expand', icon: Icons.unfold_more),
    DeviceTabSpec(label: 'Time', icon: Icons.timer),
    DeviceTabSpec(label: 'Range', icon: Icons.vertical_align_bottom),
  ];
  final DeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final ExpanderDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final tab = selectedTab ?? ExpanderDeviceTab.expand;
    return switch (tab) {
      ExpanderDeviceTab.expand => Padding(padding: const EdgeInsets.all(8), child: Column(children: [Expanded(flex: 3, child: _previewBox(DynamicsEnvelopePreview(threshold: device.expandThreshold, ratio: device.expandRatio, accent: accent, mode: DynamicsPreviewMode.expander))), const SizedBox(height: 8), Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_knob(label: 'Threshold', value: device.expandThreshold, paramId: 'expandThreshold', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsThresholdLabel(device.expandThreshold)), _knob(label: 'Ratio', value: device.expandRatio, paramId: 'expandRatio', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsRatioLabel(device.expandRatio, expander: true))]))])),
      ExpanderDeviceTab.time => Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_knob(label: 'Attack', value: device.expandAttack, paramId: 'expandAttack', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsTimeLabel(device.expandAttack)), _knob(label: 'Release', value: device.expandRelease, paramId: 'expandRelease', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsTimeLabel(device.expandRelease))])),
      ExpanderDeviceTab.range => Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [_knob(label: 'Floor', value: device.expandRange, paramId: 'expandRange', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsRangeLabel(device.expandRange))])),
    };
  }
}

class ExpanderDeviceStrip extends StatelessWidget {
  const ExpanderDeviceStrip({super.key, required this.device, required this.onParameterChanged, this.selectedTab, this.modulatedParams = const {}, this.modulationAmounts = const {}, this.connectModeLfoId, this.onModulationAssign, this.automationLinkActive = false, this.onAutomationLinkTap, this.onAutomateParameter});
  final DeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final ExpanderDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => ExpanderDevicePanel(device: device, onParameterChanged: onParameterChanged, selectedTab: selectedTab, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter);
}

class LimiterDevicePanel extends StatelessWidget {
  const LimiterDevicePanel({super.key, required this.device, required this.onParameterChanged, this.selectedTab, this.modulatedParams = const {}, this.modulationAmounts = const {}, this.connectModeLfoId, this.onModulationAssign, this.automationLinkActive = false, this.onAutomationLinkTap, this.onAutomateParameter});
  static const accent = Color(0xFFE85D4B);
  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Ceiling', icon: Icons.horizontal_rule),
    DeviceTabSpec(label: 'Time', icon: Icons.timer),
    DeviceTabSpec(label: 'Gain', icon: Icons.show_chart),
  ];
  final DeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final LimiterDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final tab = selectedTab ?? LimiterDeviceTab.ceiling;
    return switch (tab) {
      LimiterDeviceTab.ceiling => Padding(padding: const EdgeInsets.all(8), child: Column(children: [Expanded(flex: 3, child: _previewBox(DynamicsEnvelopePreview(threshold: device.limitCeiling, ceiling: device.limitCeiling, accent: accent, mode: DynamicsPreviewMode.limiter))), const SizedBox(height: 8), Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [_knob(label: 'Ceiling', value: device.limitCeiling, paramId: 'limitCeiling', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsCeilingLabel(device.limitCeiling))]))])),
      LimiterDeviceTab.time => Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [_knob(label: 'Release', value: device.limitRelease, paramId: 'limitRelease', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsTimeLabel(device.limitRelease))])),
      LimiterDeviceTab.gain => Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [_knob(label: 'Drive', value: device.limitDrive, paramId: 'limitDrive', accent: accent, onParameterChanged: onParameterChanged, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter, displayValue: dynamicsDriveLabel(device.limitDrive))])),
    };
  }
}

class LimiterDeviceStrip extends StatelessWidget {
  const LimiterDeviceStrip({super.key, required this.device, required this.onParameterChanged, this.selectedTab, this.modulatedParams = const {}, this.modulationAmounts = const {}, this.connectModeLfoId, this.onModulationAssign, this.automationLinkActive = false, this.onAutomationLinkTap, this.onAutomateParameter});
  final DeviceSnapshot device;
  final DynamicsParameterChanged onParameterChanged;
  final LimiterDeviceTab? selectedTab;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final DynamicsModulationAssign onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;
  @override
  Widget build(BuildContext context) => LimiterDevicePanel(device: device, onParameterChanged: onParameterChanged, selectedTab: selectedTab, modulatedParams: modulatedParams, modulationAmounts: modulationAmounts, connectModeLfoId: connectModeLfoId, onModulationAssign: onModulationAssign, automationLinkActive: automationLinkActive, onAutomationLinkTap: onAutomationLinkTap, onAutomateParameter: onAutomateParameter);
}
