import 'package:flutter/material.dart';

/// Shared chrome for device chain cards.
abstract final class DeviceStripTheme {
  static const stripBackground = Color(0xFF121218);
  static const cardBackground = Color(0xFF1A1A24);
  static const cardHeader = Color(0xFF22222E);
  static const toolRailBackground = Color(0xFF16161E);
  /// Nested section panel (daw_elements `panel_background` / elevated).
  static const panelElevated = Color(0xFF16161E);
  /// Deeper inset / screen well (daw_elements hierarchy hero well).
  static const panelScreen = Color(0xFF121218);
  static const cardBorder = Color(0xFF4A4A5C);
  static const cardBorderHighlight = Color(0xFF6A6A7C);
  static const cardShadow = Color(0x99000000);

  static const samplerAccent = Color(0xFFE8A54B);
  static const oscillatorAccent = Color(0xFF6EC9E8);
  static const genericAccent = Color(0xFF9A9AA8);

  static const double toolRailRadius = 10;
  static const double cardRadius = 2;
  static const double cardBorderWidth = 1.5;
  static const double headerHeight = 40;
  static const double headerTabTopInset = 0;
  static const double accentStripeWidth = 4;

  /// Header chrome (tabs live in the header; no extra divider).
  static const double cardChromeHeight = headerHeight;

  static const double slotVerticalPadding = 4;

  static const double collapsedChainTopPadding = 0;
  static const double collapsedChainBottomPadding = 4;
  static const double collapsedSlotTopPadding = 0;

  static const bassSynthAccent = Color(0xFF4ADE80);
  static const subtractiveSynthAccent = Color(0xFF7B6CF6);
  static const kickGeneratorAccent = Color(0xFFE85D4B);
  static const snareGeneratorAccent = Color(0xFFF0C14B);
  static const clapGeneratorAccent = Color(0xFFE8A0C8);
  static const cymbalGeneratorAccent = Color(0xFF9AD4E8);
  static const crashGeneratorAccent = Color(0xFF7BC8E8);
  static const gateAccent = Color(0xFF6EC9A8);
  static const compressorAccent = Color(0xFFE8A54B);
  static const expanderAccent = Color(0xFF9AD4E8);
  static const limiterAccent = Color(0xFFE85D4B);
  static const delayAccent = Color(0xFF6EC9A8);
  static const reverbAccent = Color(0xFF7B6CF6);
  static const chorusAccent = Color(0xFFE8A54B);
  static const phaserAccent = Color(0xFFE8A0C8);
  static const phaseModSynthAccent = Color(0xFFFF6B35);
  static const wavetableSynthAccent = Color(0xFF3B82F6);
  static const filterAccent = Color(0xFF5BC0EB);
  static const fourBandEqAccent = Color(0xFF78C091);
  static const frequencyShifterAccent = Color(0xFFC77DFF);
  static const resonatorBankAccent = Color(0xFFFFB454);
  static const audioReceiverAccent = Color(0xFF66D19E);
  static const midiReceiverAccent = Color(0xFFF08BB4);
  static const midiDelayAccent = Color(0xFFA78BFA);
  static const bitcrusherAccent = Color(0xFF7B6CF6);
  static const distortionAccent = Color(0xFFE85D4B);
  static const tremoloAccent = Color(0xFF4ADE80);
  static const stutterAccent = Color(0xFF57D3C4);
  static const drumMachineAccent = Color(0xFF8B7CF6);
  static const analysisAccent = Color(0xFF57D3C4);
  static const lrSplitAccent = Color(0xFF57C4E0);
  static const msSplitAccent = Color(0xFFE0A857);
  static const mbSplit2Accent = Color(0xFF6BCB9A);
  static const mbSplit3Accent = Color(0xFF7AB8E8);
  static const mbSplit4Accent = Color(0xFFE8B86B);
  static const spectralLoudSplitAccent = Color(0xFF7EC8E3);
  /// Loud / mid / quiet row highlights (visual hierarchy only).
  static const spectralLoudBandLoud = Color(0xFFF08A6B);
  static const spectralLoudBandMid = Color(0xFFE8C06B);
  static const spectralLoudBandQuiet = Color(0xFF6BA3E8);

  static Color spectralLoudBandColor(int bandIndex) => switch (bandIndex) {
        0 => spectralLoudBandLoud,
        1 => spectralLoudBandMid,
        _ => spectralLoudBandQuiet,
      };

  static Color accentForDeviceType(String type) => switch (type) {
        'simple_sampler' => samplerAccent,
        'simple_oscillator' => oscillatorAccent,
        'bass_synth' => bassSynthAccent,
        'subtractive_synth' => subtractiveSynthAccent,
        'kick_generator' => kickGeneratorAccent,
        'snare_generator' => snareGeneratorAccent,
        'clap_generator' => clapGeneratorAccent,
        'hihat_generator' => cymbalGeneratorAccent,
        'ride_generator' => const Color(0xFFB2C9F1),
        'tom_generator' => const Color(0xFFE5A7D8),
        'rimshot_generator' => const Color(0xFFF0B278),
        'crash_generator' => crashGeneratorAccent,
        'gate' => gateAccent,
        'compressor' => compressorAccent,
        'expander' => expanderAccent,
        'limiter' => limiterAccent,
        'ducker' => const Color(0xFFF472B6),
        'utility' => const Color(0xFF94A3B8),
        'delay' => delayAccent,
        'reverb' => reverbAccent,
        'chorus' => chorusAccent,
        'phaser' => phaserAccent,
        'phase_mod_synth' => phaseModSynthAccent,
        'wavetable_synth' => wavetableSynthAccent,
        'filter' => filterAccent,
        'four_band_eq' => fourBandEqAccent,
        'frequency_shifter' => frequencyShifterAccent,
        'resonator_bank' => resonatorBankAccent,
        'audio_receiver' => audioReceiverAccent,
        'midi_receiver' => midiReceiverAccent,
        'midi_delay' => midiDelayAccent,
        'bitcrusher' => bitcrusherAccent,
        'distortion' => distortionAccent,
        'tremolo' => tremoloAccent,
        'stutter_fx' => stutterAccent,
        'dc_offset' => const Color(0xFF7DD3C0),
        'de_crackler' => const Color(0xFFF0B429),
        'de_esser' => const Color(0xFFC084FC),
        'de_hum' => const Color(0xFF60A5FA),
        'de_noise' => const Color(0xFF94A3B8),
        'drum_machine' => drumMachineAccent,
        'device_chain' => const Color(0xFF62C7B5),
        'lr_split' => lrSplitAccent,
        'ms_split' => msSplitAccent,
        'mb_split_2' => mbSplit2Accent,
        'mb_split_3' => mbSplit3Accent,
        'mb_split_4' => mbSplit4Accent,
        'spectral_loud_split' => spectralLoudSplitAccent,
        'granular_formant_synth' => const Color(0xFFDA70D6),
        'oscilloscope' ||
        'spectrum_analyzer' ||
        'loudness_meter' ||
        'stereo_imager' =>
          analysisAccent,
        _ => genericAccent,
      };

  static String labelForDeviceType(String type) => switch (type) {
        'simple_sampler' => 'Sampler',
        'simple_oscillator' => 'Oscillator',
        'bass_synth' => 'Bass Synth',
        'subtractive_synth' => 'Subtractive Synth',
        'kick_generator' => 'Kick Generator',
        'snare_generator' => 'Snare Generator',
        'clap_generator' => 'Clap Generator',
        'hihat_generator' => 'Hi-Hat',
        'ride_generator' => 'Ride',
        'tom_generator' => 'Tom',
        'rimshot_generator' => 'Rimshot',
        'crash_generator' => 'Crash Generator',
        'gate' => 'Gate',
        'compressor' => 'Compressor',
        'expander' => 'Expander',
        'limiter' => 'Limiter',
        'ducker' => 'Ducker',
        'utility' => 'Utility',
        'delay' => 'Delay',
        'reverb' => 'Reverb',
        'chorus' => 'Chorus',
        'phaser' => 'Phaser',
        'phase_mod_synth' => 'Phase Mod Synth',
        'wavetable_synth' => 'Wavetable Synth',
        'filter' => 'Filter',
        'four_band_eq' => '4-Band EQ',
        'frequency_shifter' => 'Ring Mod',
        'resonator_bank' => 'RESONATE',
        'audio_receiver' => 'Audio Receiver',
        'midi_receiver' => 'MIDI Receiver',
        'midi_delay' => 'MIDI Delay',
        'bitcrusher' => 'Bitcrusher',
        'distortion' => 'Distortion',
        'tremolo' => 'Tremolo',
        'stutter_fx' => 'Stutter',
        'dc_offset' => 'DC Offset',
        'de_crackler' => 'De-Crackler',
        'de_esser' => 'De-Esser',
        'de_hum' => 'De-Hum',
        'de_noise' => 'De-Noise',
        'drum_machine' => 'Drum Machine',
        'device_chain' => 'Chain',
        'lr_split' => 'LR Split',
        'ms_split' => 'Mid-Side Split',
        'mb_split_2' => '2-Band Split',
        'mb_split_3' => '3-Band Split',
        'mb_split_4' => '4-Band Split',
        'spectral_loud_split' => 'Spectral Loud Split',
        'granular_formant_synth' => 'Grain Form',
        'oscilloscope' => 'Oscilloscope',
        'spectrum_analyzer' => 'Spectrum Analyzer',
        'loudness_meter' => 'Loudness Meter',
        'stereo_imager' => 'Stereo Imager',
        _ => type,
      };

  /// Opacity for pre-gain devices while a track is frozen (track_gain stays full).
  static const double frozenPreGainOpacity = 0.38;

  static Widget wrapFrozenPreGainDimmed({
    required bool dimmed,
    required Widget child,
  }) {
    if (!dimmed) {
      return child;
    }
    return Opacity(
      opacity: frozenPreGainOpacity,
      child: IgnorePointer(child: child),
    );
  }
}
