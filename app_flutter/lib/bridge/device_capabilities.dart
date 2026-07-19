abstract final class DeviceCapabilities {
  static const virtualStripHosts = {
    'simple_oscillator',
    'subtractive_synth',
    'phase_mod_synth',
    'wavetable_synth',
    'bass_synth',
    'granular_formant_synth',
    'simple_sampler',
  };

  static const noteFx = {'midi_delay'};

  static const audioFx = {
    'gate',
    'compressor',
    'expander',
    'limiter',
    'filter',
    'four_band_eq',
    'frequency_shifter',
    'resonator_bank',
    'delay',
    'reverb',
    'chorus',
    'phaser',
    'bitcrusher',
    'distortion',
    'tremolo',
    'stutter_fx',
    'dc_offset',
    'de_crackler',
    'de_esser',
    'de_hum',
    'de_noise',
  };
}
