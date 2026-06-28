import 'package:flutter/material.dart';

/// Shared chrome for device chain cards.
abstract final class DeviceStripTheme {
  static const stripBackground = Color(0xFF121218);
  static const cardBackground = Color(0xFF1A1A24);
  static const cardHeader = Color(0xFF22222E);
  static const toolRailBackground = Color(0xFF16161E);
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
  static const bitcrusherAccent = Color(0xFF7B6CF6);
  static const distortionAccent = Color(0xFFE85D4B);
  static const tremoloAccent = Color(0xFF4ADE80);

  static Color accentForDeviceType(String type) => switch (type) {
        'simple_sampler' => samplerAccent,
        'simple_oscillator' => oscillatorAccent,
        'bass_synth' => bassSynthAccent,
        'subtractive_synth' => subtractiveSynthAccent,
        'kick_generator' => kickGeneratorAccent,
        'snare_generator' => snareGeneratorAccent,
        'clap_generator' => clapGeneratorAccent,
        'cymbal_generator' => cymbalGeneratorAccent,
        'crash_generator' => crashGeneratorAccent,
        'gate' => gateAccent,
        'compressor' => compressorAccent,
        'expander' => expanderAccent,
        'limiter' => limiterAccent,
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
        'bitcrusher' => bitcrusherAccent,
        'distortion' => distortionAccent,
        'tremolo' => tremoloAccent,
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
        'cymbal_generator' => 'Cymbal Generator',
        'crash_generator' => 'Crash Generator',
        'gate' => 'Gate',
        'compressor' => 'Compressor',
        'expander' => 'Expander',
        'limiter' => 'Limiter',
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
        'bitcrusher' => 'Bitcrusher',
        'distortion' => 'Distortion',
        'tremolo' => 'Tremolo',
        _ => type,
      };
}
