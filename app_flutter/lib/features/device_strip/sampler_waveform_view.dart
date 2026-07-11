import 'package:flutter/material.dart';

import '../sample_library/sample_library_screen.dart';
import 'device_automation_spinner.dart';
import 'modulator_polarity.dart';

part 'sampler_waveform_view_sampler_waveform_density.dart';
part 'sampler_waveform_view_private_sampler_waveform_view_state.dart';
part 'sampler_waveform_view_private_waveform_drag.dart';
part 'sampler_waveform_view_private_sampler_waveform_empty_state.dart';
part 'sampler_waveform_view_private_handle.dart';
part 'sampler_waveform_view_private_legend_chip.dart';
part 'sampler_waveform_view_spinner_modulation_props.dart';
part 'sampler_waveform_view_sampler_root_key_chip.dart';
part 'sampler_waveform_view_private_sampler_root_key_chip_state.dart';
part 'sampler_waveform_view_sampler_fine_tune_chip.dart';
part 'sampler_waveform_view_private_sampler_fine_tune_chip_state.dart';
part 'sampler_waveform_view_sampler_playback_identity_bar.dart';
part 'sampler_waveform_view_private_playback_mode_segments.dart';
part 'sampler_waveform_view_private_playback_segment.dart';
part 'sampler_waveform_view_private_root_step_hit.dart';

/// Strip: loop region only. Editor: trim bounds + optional loop band inside trim.
/// Shared waveform surface for sampler Wave tab (strip + fullscreen).
class SamplerWaveformView extends StatefulWidget {
  const SamplerWaveformView({
    super.key,
    required this.peaks,
    required this.durationSec,
    required this.trimStartSec,
    required this.trimEndSec,
    required this.regionStartSec,
    required this.regionEndSec,
    required this.density,
    required this.waveColor,
    required this.accentColor,
    this.onTrimChanged,
    this.onRegionChanged,
    this.onPreview,
    this.loopRegionEnabled = false,
    this.emptyHint,
    this.onLoadSample,
  });

  final List<double> peaks;
  final double durationSec;
  final double trimStartSec;
  final double trimEndSec;
  final double regionStartSec;
  final double regionEndSec;
  final SamplerWaveformDensity density;
  final Color waveColor;
  final Color accentColor;
  final void Function(double startSec, double endSec)? onTrimChanged;
  final void Function(double startSec, double endSec)? onRegionChanged;
  final VoidCallback? onPreview;
  final bool loopRegionEnabled;
  final String? emptyHint;
  final VoidCallback? onLoadSample;

  bool get hasLoop => regionEndSec > 0;
  bool get showLoopBand =>
      loopRegionEnabled && (hasLoop || onRegionChanged != null);

  @override
  State<SamplerWaveformView> createState() => _SamplerWaveformViewState();
}

/// Formats seconds for sampler time readouts (e.g. 0.42s).
String formatSamplerDurationSec(double sec) {
  if (sec >= 10) return '${sec.toStringAsFixed(1)}s';
  return '${sec.toStringAsFixed(2)}s';
}

/// Playback window label for the Wave tab footer.
String formatSamplerPlaybackRange({
  required int playbackMode,
  required double durationSec,
  required double trimStartSec,
  required double trimEndSec,
  required double regionStartSec,
  required double regionEndSec,
}) {
  final trimEnd = trimEndSec > 0 ? trimEndSec : durationSec;
  final trimStart = trimStartSec.clamp(0.0, trimEnd).toDouble();
  switch (playbackMode) {
    case 1:
      if (regionEndSec > 0) {
        return 'Loop ${formatSamplerDurationSec(regionStartSec)}–${formatSamplerDurationSec(regionEndSec)}';
      }
      return 'Loop ${formatSamplerDurationSec(trimStart)}–${formatSamplerDurationSec(trimEnd)}';
    case 2:
      return 'Rev ${formatSamplerDurationSec(trimStart)}–${formatSamplerDurationSec(trimEnd)}';
    default:
      return 'Shot ${formatSamplerDurationSec(trimStart)}–${formatSamplerDurationSec(trimEnd)}';
  }
}

/// Formats a MIDI note number as e.g. C3.
String formatSamplerMidiNote(int pitch) {
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
  final clamped = pitch.clamp(0, 127);
  return '${names[clamped % 12]}${(clamped ~/ 12) - 1}';
}

/// Formats fine tune cents for the identity bar chip.
String formatSamplerFineTune(double cents) {
  final rounded = cents.round().clamp(-100, 100);
  if (rounded == 0) return '0¢';
  if (rounded > 0) return '+$rounded¢';
  return '$rounded¢';
}

/// Modulation + automation wiring for identity-bar spinners.
/// Root key stepper — drag or tap ▲/▼ to change MIDI note.
/// Fine tune stepper — ± cents relative to root key.
/// Root + play mode in one strip panel (matches device inset styling).
