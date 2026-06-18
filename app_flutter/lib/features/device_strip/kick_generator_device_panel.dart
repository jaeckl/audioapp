import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'kick_envelope_preview.dart';
import 'rotary_knob.dart';

enum KickDeviceTab { body, trans, amp }

class KickGeneratorDevicePanel extends StatefulWidget {
  const KickGeneratorDevicePanel({
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
  final KickDeviceTab? selectedTab;
  final ValueChanged<KickDeviceTab>? onTabChanged;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const accent = DeviceStripTheme.kickGeneratorAccent;

  static const containerTabs = <DeviceTabSpec>[
    DeviceTabSpec(label: 'Body', icon: Icons.circle),
    DeviceTabSpec(label: 'Trans', icon: Icons.bolt),
    DeviceTabSpec(label: 'Amp', icon: Icons.show_chart),
  ];

  @override
  State<KickGeneratorDevicePanel> createState() => _KickGeneratorDevicePanelState();
}

class _KickGeneratorDevicePanelState extends State<KickGeneratorDevicePanel> {
  late KickDeviceTab _tab;

  KickDeviceTab get _activeTab => widget.selectedTab ?? _tab;

  @override
  void initState() {
    super.initState();
    _tab = KickDeviceTab.body;
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
      accentColor: KickGeneratorDevicePanel.accent,
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

  Widget _bodyTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: _previewBox(
              child: KickEnvelopePreview(
                pitch: widget.device.kickPitch,
                punch: widget.device.kickPunch,
                decay: widget.device.kickDecay,
                click: widget.device.kickClick,
                accent: KickGeneratorDevicePanel.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _knob(
                  label: 'Pitch',
                  value: widget.device.kickPitch,
                  paramId: 'kickPitch',
                  displayValue: kickPitchLabel(widget.device.kickPitch),
                  onChanged: (v) => widget.onParameterChanged('kickPitch', v),
                ),
                _knob(
                  label: 'Punch',
                  value: widget.device.kickPunch,
                  paramId: 'kickPunch',
                  displayValue: '${(widget.device.kickPunch * 100).round()}%',
                  onChanged: (v) => widget.onParameterChanged('kickPunch', v),
                ),
                _knob(
                  label: 'Tone',
                  value: widget.device.kickTone,
                  paramId: 'kickTone',
                  displayValue: '${(widget.device.kickTone * 100).round()}%',
                  onChanged: (v) => widget.onParameterChanged('kickTone', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transTab() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: _previewBox(
              child: KickEnvelopePreview(
                pitch: widget.device.kickPitch,
                punch: widget.device.kickPunch,
                decay: widget.device.kickDecay,
                click: widget.device.kickClick,
                accent: KickGeneratorDevicePanel.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _knob(
                  label: 'Click',
                  value: widget.device.kickClick,
                  paramId: 'kickClick',
                  displayValue: '${(widget.device.kickClick * 100).round()}%',
                  onChanged: (v) => widget.onParameterChanged('kickClick', v),
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
            value: widget.device.kickDecay,
            paramId: 'kickDecay',
            displayValue: kickDecayLabel(widget.device.kickDecay),
            onChanged: (v) => widget.onParameterChanged('kickDecay', v),
          ),
          _knob(
            label: 'Velocity',
            value: widget.device.kickVelocity,
            paramId: 'kickVelocity',
            displayValue: '${(widget.device.kickVelocity * 100).round()}%',
            onChanged: (v) => widget.onParameterChanged('kickVelocity', v),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabBody = switch (_activeTab) {
      KickDeviceTab.body => _bodyTab(),
      KickDeviceTab.trans => _transTab(),
      KickDeviceTab.amp => _ampTab(),
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
              'KICK GENERATOR',
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
