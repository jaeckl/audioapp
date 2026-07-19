import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'cymbal_decay_preview.dart';
import 'crash_model_ui_registry.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'device_tab_bar.dart';
import 'drum_keytrack_toggle.dart';
import 'percussion_panel_layout.dart';
import 'rotary_knob.dart';

class CrashGeneratorDevicePanel extends StatelessWidget {
  static const registeredDeviceTypes = ['crash_generator'];
  const CrashGeneratorDevicePanel({
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

  final CrashGeneratorDeviceSnapshot device;
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

  static const accent = DeviceStripTheme.crashGeneratorAccent;

  static const double designWidth = PercussionPanelLayout.designWidth;

  static const containerTabs = <DeviceTabSpec>[];

  @override
  Widget build(BuildContext context) {
    final knobs = CrashModelUiRegistry.knobs;
    CrashKnobSpec spec(String parameterId) =>
        knobs.firstWhere((candidate) => candidate.paramId == parameterId);
    final bench = PercussionPanelLayout(
      flexes: const [5, 6],
      cards: [
        PercussionControlCard(
          child: Column(
            children: [
              PercussionMiniPreview(
                child: CymbalDecayPreview(
                  color: device.crashColor,
                  decay: device.crashDecay,
                  accent: accent,
                ),
              ),
              Expanded(child: Center(child: _buildKnob(spec('crashPitch')))),
            ],
          ),
        ),
        PercussionControlCard(
          child: PercussionKnobRows(
            rows: [
              [
                _buildKnob(spec('crashColor')),
                _buildKnob(spec('crashSpread')),
              ],
              [_buildKnob(spec('crashDecay'))],
            ],
          ),
        ),
      ],
    );
    return PercussionPanelSurface(
      title: 'CRASH GENERATOR',
      embeddedInCard: embeddedInCard,
      child: bench,
    );
  }

  Widget _buildKnob(CrashKnobSpec spec) {
    final value = spec.value(device);
    final paramId = spec.paramId;
    final knob = RotaryKnob(
      label: paramId == 'crashPitch' && device.crashKeyTrack >= 0.5
          ? 'Tune'
          : spec.label,
      value: value.clamp(0.0, 1.0),
      size: DeviceKnobSizes.strip,
      displayValue: paramId == 'crashPitch'
          ? percussionPitchModeLabel(
              value,
              49,
              keyTrack: device.crashKeyTrack >= 0.5,
            )
          : spec.format(value),
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
    if (paramId != 'crashPitch') return knob;
    return PercussionPitchControl(
      active: device.crashKeyTrack >= 0.5,
      accent: accent,
      knob: knob,
      onChanged: (active) =>
          onParameterChanged('crashKeyTrack', active ? 1.0 : 0.0),
    );
  }
}
