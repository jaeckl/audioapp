import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'cymbal_decay_preview.dart';
import 'cymbal_model_ui_registry.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'drum_keytrack_toggle.dart';
import 'percussion_panel_layout.dart';
import 'rotary_knob.dart';

class CymbalGeneratorDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['cymbal_generator'];
  const CymbalGeneratorDevicePanel({
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

  final CymbalGeneratorDeviceSnapshot device;
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

  static const accent = DeviceStripTheme.cymbalGeneratorAccent;

  static const double designWidth = PercussionPanelLayout.designWidth;

  static const containerTabs = <DeviceTabSpec>[];

  @override
  Widget build(BuildContext context) {
    final knobs = CymbalModelUiRegistry.knobs;
    CymbalKnobSpec spec(String parameterId) =>
        knobs.firstWhere((candidate) => candidate.paramId == parameterId);
    final bench = PercussionPanelLayout(
      cards: [
        PercussionControlCard(
          child: Column(
            children: [
              PercussionMiniPreview(
                child: CymbalDecayPreview(
                  color: device.cymbalColor,
                  decay: device.cymbalDecay,
                  accent: accent,
                ),
              ),
              Expanded(child: Center(child: _buildKnob(spec('cymbalPitch')))),
            ],
          ),
        ),
        PercussionControlCard(
          child: PercussionKnobColumn(
            children: [
              _buildKnob(spec('cymbalColor')),
              _buildKnob(spec('cymbalWidth')),
            ],
          ),
        ),
        PercussionControlCard(
          child: PercussionKnobColumn(
            children: [_buildKnob(spec('cymbalDecay'))],
          ),
        ),
      ],
    );
    return PercussionPanelSurface(
      title: 'CYMBAL GENERATOR',
      embeddedInCard: embeddedInCard,
      child: bench,
    );
  }

  Widget _buildKnob(CymbalKnobSpec spec) {
    final value = spec.value(device);
    final paramId = spec.paramId;
    final knob = RotaryKnob(
      label: paramId == 'cymbalPitch' && device.cymbalKeyTrack >= 0.5
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
    if (paramId != 'cymbalPitch') return knob;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        knob,
        const SizedBox(width: 4),
        DrumKeyTrackToggle(
          active: device.cymbalKeyTrack >= 0.5,
          accent: accent,
          onChanged: (active) =>
              onParameterChanged('cymbalKeyTrack', active ? 1.0 : 0.0),
        ),
      ],
    );
  }
}
