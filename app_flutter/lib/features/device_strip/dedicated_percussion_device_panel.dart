import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'percussion_panel_layout.dart';
import 'rotary_knob.dart';

class DedicatedPercussionDevicePanel extends StatelessWidget {
  const DedicatedPercussionDevicePanel({
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

  final DedicatedPercussionDeviceSnapshot device;
  final void Function(String parameterId, double value) onParameterChanged;
  final Set<String> modulatedParams;
  final Set<String> automatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;
  final ValueChanged<String>? onAutomateParameter;

  @override
  Widget build(BuildContext context) {
    final config = _PercussionUiConfig.forType(device.type);
    return PercussionPanelLayout(
      flexes: const [5, 6],
      cards: [
        PercussionControlCard(
          child: PercussionKnobRows(
            rows: [
              [_knob(config, config.columns.first.first)],
              [
                for (final spec in config.columns.first.skip(1))
                  _knob(config, spec),
              ],
            ],
          ),
        ),
        PercussionControlCard(
          child: PercussionKnobRows(
            rows: [
              for (final row in config.columns.skip(1))
                [for (final spec in row) _knob(config, spec)],
            ],
          ),
        ),
      ],
    );
  }

  Widget _knob(_PercussionUiConfig config, _PercussionKnobSpec spec) {
    final value = device.value(spec.id, spec.fallback);
    final keyTrack = device.value(config.keyTrackId, 0.0) >= 0.5;
    final isPitch = spec.id == config.pitchId;
    final knob = RotaryKnob(
      label: isPitch && keyTrack ? 'Tune' : spec.label,
      value: value.clamp(0.0, 1.0),
      size: DeviceKnobSizes.strip,
      displayValue: isPitch
          ? _pitchLabel(value, config.anchorPitch, keyTrack)
          : '${(value * 100).round()}%',
      accentColor: config.accent,
      modulationActive: modulatedParams.contains(spec.id),
      automationActive: automatedParams.contains(spec.id),
      modulationAmount: modulationAmounts[spec.id] ?? 0.0,
      parameterId: spec.id,
      connectModeActive: connectModeLfoId != null,
      onModulationAssign: onModulationAssign == null
          ? null
          : (amount) => onModulationAssign!(spec.id, amount),
      linkModeActive: automationLinkActive,
      onLinkTap: onAutomationLinkTap == null
          ? null
          : () => onAutomationLinkTap!(spec.id),
      onAutomateRequest: onAutomateParameter == null
          ? null
          : () => onAutomateParameter!(spec.id),
      onChanged: (next) => onParameterChanged(spec.id, next),
    );
    if (!isPitch) return knob;
    return PercussionPitchControl(
      active: keyTrack,
      accent: config.accent,
      knob: knob,
      onChanged: (active) =>
          onParameterChanged(config.keyTrackId, active ? 1.0 : 0.0),
    );
  }
}

String _pitchLabel(double normalized, int anchorPitch, bool keyTrack) {
  const names = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];
  final semitones = ((normalized.clamp(0.0, 1.0) - 0.5) * 48).round();
  if (keyTrack)
    return semitones == 0 ? '0 st' : '${semitones > 0 ? '+' : ''}$semitones st';
  final midi = (anchorPitch + semitones).clamp(0, 127);
  return '${names[midi % 12]}${midi ~/ 12 - 1}';
}

class _PercussionKnobSpec {
  const _PercussionKnobSpec(this.id, this.label, this.fallback);
  final String id;
  final String label;
  final double fallback;
}

class _PercussionUiConfig {
  const _PercussionUiConfig(this.anchorPitch, this.pitchId, this.keyTrackId,
      this.accent, this.columns);
  final int anchorPitch;
  final String pitchId;
  final String keyTrackId;
  final Color accent;
  final List<List<_PercussionKnobSpec>> columns;

  static _PercussionUiConfig forType(String type) => switch (type) {
        'ride_generator' => const _PercussionUiConfig(
              51, 'ridePitch', 'rideKeyTrack', Color(0xFFB2C9F1), [
            [
              _PercussionKnobSpec('ridePitch', 'Pitch', .5),
              _PercussionKnobSpec('rideBrightness', 'Bright', .62),
              _PercussionKnobSpec('rideBell', 'Bell', .28)
            ],
            [
              _PercussionKnobSpec('rideDecay', 'Decay', .62),
              _PercussionKnobSpec('rideDamping', 'Damp', .35)
            ],
            [
              _PercussionKnobSpec('rideWidth', 'Width', .3),
              _PercussionKnobSpec('rideVelocity', 'Velocity', 1)
            ],
          ]),
        'tom_generator' => const _PercussionUiConfig(
              45, 'tomPitch', 'tomKeyTrack', Color(0xFFE5A7D8), [
            [
              _PercussionKnobSpec('tomPitch', 'Pitch', .42),
              _PercussionKnobSpec('tomBend', 'Bend', .38),
              _PercussionKnobSpec('tomBody', 'Body', .72)
            ],
            [
              _PercussionKnobSpec('tomDecay', 'Decay', .42),
              _PercussionKnobSpec('tomAttack', 'Attack', .35)
            ],
            [
              _PercussionKnobSpec('tomNoise', 'Noise', .16),
              _PercussionKnobSpec('tomVelocity', 'Velocity', 1)
            ],
          ]),
        'rimshot_generator' => const _PercussionUiConfig(
              37, 'rimshotPitch', 'rimshotKeyTrack', Color(0xFFF0B278), [
            [
              _PercussionKnobSpec('rimshotPitch', 'Pitch', .52),
              _PercussionKnobSpec('rimshotTone', 'Tone', .62),
              _PercussionKnobSpec('rimshotSnap', 'Snap', .74)
            ],
            [
              _PercussionKnobSpec('rimshotDecay', 'Decay', .24),
              _PercussionKnobSpec('rimshotBody', 'Body', .38)
            ],
            [_PercussionKnobSpec('rimshotVelocity', 'Velocity', 1)],
          ]),
        _ => const _PercussionUiConfig(
              42, 'hihatPitch', 'hihatKeyTrack', Color(0xFF9AD4E8), [
            [
              _PercussionKnobSpec('hihatPitch', 'Pitch', .5),
              _PercussionKnobSpec('hihatColor', 'Color', .68),
              _PercussionKnobSpec('hihatTightness', 'Tight', .72)
            ],
            [
              _PercussionKnobSpec('hihatDecay', 'Decay', .28),
              _PercussionKnobSpec('hihatNoise', 'Noise', .34)
            ],
            [
              _PercussionKnobSpec('hihatWidth', 'Width', .25),
              _PercussionKnobSpec('hihatVelocity', 'Velocity', 1)
            ],
          ]),
      };
}
