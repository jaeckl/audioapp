import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'drum_keytrack_toggle.dart';
import 'kick_envelope_preview.dart';
import 'kick_model_ui_registry.dart';
import 'percussion_panel_layout.dart';
import 'rotary_knob.dart';

class KickGeneratorDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['kick_generator'];
  const KickGeneratorDevicePanel({
    super.key,
    required this.device,
    required this.onParameterChanged,
    this.embeddedInCard = false,
    this.modulatedParams = const {},
    this.automatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
    this.onAutomateParameter,
  });

  final KickGeneratorDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final bool embeddedInCard;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  static const accent = DeviceStripTheme.kickGeneratorAccent;

  static const double designWidth = PercussionPanelLayout.designWidth;

  /// Kick bench uses header-only chrome — no container tabs.
  static const containerTabs = <DeviceTabSpec>[];

  @override
  Widget build(BuildContext context) {
    final knobs = KickModelUiRegistry.knobs;
    KickKnobSpec spec(String parameterId) =>
        knobs.firstWhere((candidate) => candidate.paramId == parameterId);
    final bench = PercussionPanelLayout(
      cards: [
        PercussionControlCard(
          child: Column(
            children: [
              PercussionMiniPreview(
                child: KickEnvelopePreview(
                  pitch: device.kickPitch,
                  punch: device.kickPunch,
                  decay: device.kickDecay,
                  click: device.kickClick,
                  accent: accent,
                ),
              ),
              Expanded(child: Center(child: _buildKnob(spec('kickPitch')))),
            ],
          ),
        ),
        PercussionControlCard(
          child: PercussionKnobColumn(
            children: [
              _buildKnob(spec('kickPunch')),
              _buildKnob(spec('kickTone')),
            ],
          ),
        ),
        PercussionControlCard(
          child: PercussionKnobColumn(
            children: [
              _buildKnob(spec('kickClick')),
              _buildKnob(spec('kickDecay')),
            ],
          ),
        ),
      ],
    );
    return PercussionPanelSurface(
      title: 'KICK GENERATOR',
      embeddedInCard: embeddedInCard,
      child: bench,
    );
  }

  Widget _buildKnob(KickKnobSpec spec) {
    final value = spec.value(device);
    final paramId = spec.paramId;
    final knob = RotaryKnob(
      label: paramId == 'kickPitch' && device.kickKeyTrack >= 0.5
          ? 'Tune'
          : spec.label,
      value: value.clamp(0.0, 1.0),
      size: DeviceKnobSizes.strip,
      displayValue: spec.format(value),
      accentColor: accent,
      modulationActive: modulatedParams.contains(paramId),
      automationActive: automatedParams.contains(paramId),
      modulationAmount: modulationAmounts[paramId] ?? 0.0,
      parameterId: paramId,
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
    if (paramId != 'kickPitch') return knob;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        knob,
        const SizedBox(width: 4),
        DrumKeyTrackToggle(
          active: device.kickKeyTrack >= 0.5,
          accent: accent,
          onChanged: (active) =>
              onParameterChanged('kickKeyTrack', active ? 1.0 : 0.0),
        ),
      ],
    );
  }
}
