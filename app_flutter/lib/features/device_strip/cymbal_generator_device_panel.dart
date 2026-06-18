import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'cymbal_decay_preview.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';

enum CymbalDeviceTab { metal, decay, amp }

class CymbalGeneratorDevicePanel extends StatefulWidget {
  const CymbalGeneratorDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.embeddedInCard = false,
    this.selectedTab,
    this.onTabChanged,
    this.modulatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final DeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final bool embeddedInCard;
  final CymbalDeviceTab? selectedTab;
  final ValueChanged<CymbalDeviceTab>? onTabChanged;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const accent = DeviceStripTheme.cymbalGeneratorAccent;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Metal', icon: Icons.blur_on),
    DeviceTabSpec(label: 'Decay', icon: Icons.timelapse),
    DeviceTabSpec(label: 'Amp', icon: Icons.show_chart),
  ];

  @override
  State<CymbalGeneratorDevicePanel> createState() => _CymbalGeneratorDevicePanelState();
}

class _CymbalGeneratorDevicePanelState extends State<CymbalGeneratorDevicePanel> {
  late CymbalDeviceTab _tab;

  CymbalDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  @override
  void initState() {
    super.initState();
    _tab = CymbalDeviceTab.metal;
  }

  Widget _knob({
    required String label,
    required double value,
    required String paramId,
    required ValueChanged<double> onChanged,
    String? displayValue,
  }) {
    return RotaryKnob(
      label: label,
      value: value.clamp(0.0, 1.0),
      size: DeviceKnobSizes.strip,
      displayValue: displayValue,
      accentColor: CymbalGeneratorDevicePanel.accent,
      modulationActive: widget.modulatedParams.contains(paramId),
      modulationAmount: widget.modulationAmounts[paramId] ?? 0.0,
      connectModeActive: widget.connectModeLfoId != null,
      onModulationAssign: widget.onModulationAssign != null
          ? (amount) => widget.onModulationAssign!(paramId, amount)
          : null,
      linkModeActive: widget.automationLinkActive,
      onLinkTap:
          widget.onAutomationLinkTap != null ? () => widget.onAutomationLinkTap!(paramId) : null,
      onAutomateRequest:
          widget.onAutomateParameter != null ? () => widget.onAutomateParameter!(paramId) : null,
      onChanged: onChanged,
    );
  }

  Widget _previewBox({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(6), child: child),
    );
  }

  Widget _preview() {
    return CymbalDecayPreview(
      metal: widget.device.cymbalMetal,
      brightness: widget.device.cymbalBrightness,
      decay: widget.device.cymbalDecay,
      accent: CymbalGeneratorDevicePanel.accent,
    );
  }

  Widget _metalTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(flex: 3, child: _previewBox(child: _preview())),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _knob(
                  label: 'Metal',
                  value: widget.device.cymbalMetal,
                  paramId: 'cymbalMetal',
                  displayValue: '${(widget.device.cymbalMetal * 100).round()}%',
                  onChanged: (v) => widget.onParameterChanged('cymbalMetal', v),
                ),
                _knob(
                  label: 'Bright',
                  value: widget.device.cymbalBrightness,
                  paramId: 'cymbalBrightness',
                  displayValue: '${(widget.device.cymbalBrightness * 100).round()}%',
                  onChanged: (v) => widget.onParameterChanged('cymbalBrightness', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _decayTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _knob(
            label: 'Decay',
            value: widget.device.cymbalDecay,
            paramId: 'cymbalDecay',
            displayValue: cymbalDecayLabel(widget.device.cymbalDecay),
            onChanged: (v) => widget.onParameterChanged('cymbalDecay', v),
          ),
          _knob(
            label: 'Choke',
            value: widget.device.cymbalChoke,
            paramId: 'cymbalChoke',
            displayValue: '${(widget.device.cymbalChoke * 100).round()}%',
            onChanged: (v) => widget.onParameterChanged('cymbalChoke', v),
          ),
        ],
      ),
    );
  }

  Widget _ampTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: _knob(
        label: 'Velocity',
        value: widget.device.cymbalVelocity,
        paramId: 'cymbalVelocity',
        displayValue: '${(widget.device.cymbalVelocity * 100).round()}%',
        onChanged: (v) => widget.onParameterChanged('cymbalVelocity', v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabBody = switch (_activeTab) {
      CymbalDeviceTab.metal => _metalTab(),
      CymbalDeviceTab.decay => _decayTab(),
      CymbalDeviceTab.amp => _ampTab(),
    };

    if (widget.embeddedInCard) {
      return tabBody;
    }

    return Material(
      color: const Color(0xFF1C1C24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(
              'CYMBAL GENERATOR',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(child: tabBody),
        ],
      ),
    );
  }
}
