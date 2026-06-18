import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'rotary_knob.dart';
import 'snare_envelope_preview.dart';

enum SnareDeviceTab { body, snares, amp }

class SnareGeneratorDevicePanel extends StatefulWidget {
  const SnareGeneratorDevicePanel({
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
  final SnareDeviceTab? selectedTab;
  final ValueChanged<SnareDeviceTab>? onTabChanged;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const accent = DeviceStripTheme.snareGeneratorAccent;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Body', icon: Icons.circle),
    DeviceTabSpec(label: 'Snares', icon: Icons.grain),
    DeviceTabSpec(label: 'Amp', icon: Icons.show_chart),
  ];

  @override
  State<SnareGeneratorDevicePanel> createState() => _SnareGeneratorDevicePanelState();
}

class _SnareGeneratorDevicePanelState extends State<SnareGeneratorDevicePanel> {
  late SnareDeviceTab _tab;

  SnareDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  @override
  void initState() {
    super.initState();
    _tab = SnareDeviceTab.body;
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
      accentColor: SnareGeneratorDevicePanel.accent,
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
    return SnareEnvelopePreview(
      body: widget.device.snareBody,
      tune: widget.device.snareTune,
      snares: widget.device.snareSnares,
      snap: widget.device.snareSnap,
      decay: widget.device.snareDecay,
      accent: SnareGeneratorDevicePanel.accent,
    );
  }

  Widget _bodyTab() {
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
                  label: 'Body',
                  value: widget.device.snareBody,
                  paramId: 'snareBody',
                  displayValue: '${(widget.device.snareBody * 100).round()}%',
                  onChanged: (v) => widget.onParameterChanged('snareBody', v),
                ),
                _knob(
                  label: 'Tune',
                  value: widget.device.snareTune,
                  paramId: 'snareTune',
                  displayValue: snareTuneLabel(widget.device.snareTune),
                  onChanged: (v) => widget.onParameterChanged('snareTune', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _snaresTab() {
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
                  label: 'Snares',
                  value: widget.device.snareSnares,
                  paramId: 'snareSnares',
                  displayValue: '${(widget.device.snareSnares * 100).round()}%',
                  onChanged: (v) => widget.onParameterChanged('snareSnares', v),
                ),
                _knob(
                  label: 'Snap',
                  value: widget.device.snareSnap,
                  paramId: 'snareSnap',
                  displayValue: '${(widget.device.snareSnap * 100).round()}%',
                  onChanged: (v) => widget.onParameterChanged('snareSnap', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ampTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _knob(
            label: 'Decay',
            value: widget.device.snareDecay,
            paramId: 'snareDecay',
            displayValue: snareDecayLabel(widget.device.snareDecay),
            onChanged: (v) => widget.onParameterChanged('snareDecay', v),
          ),
          _knob(
            label: 'Velocity',
            value: widget.device.snareVelocity,
            paramId: 'snareVelocity',
            displayValue: '${(widget.device.snareVelocity * 100).round()}%',
            onChanged: (v) => widget.onParameterChanged('snareVelocity', v),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabBody = switch (_activeTab) {
      SnareDeviceTab.body => _bodyTab(),
      SnareDeviceTab.snares => _snaresTab(),
      SnareDeviceTab.amp => _ampTab(),
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
              'SNARE GENERATOR',
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
