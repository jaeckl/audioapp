// GENERATED FILE. Run tools/generate_device_panel_tabs.py.
// ignore_for_file: directives_ordering

import 'device_tab_bar.dart';
import 'bass_synth_device_panel.dart';
import 'clap_generator_device_panel.dart';
import 'crash_generator_device_panel.dart';
import 'cymbal_generator_device_panel.dart';
import 'dynamics_fx_panels.dart';
import 'frequency_fx_panels.dart';
import 'granular_device_panel.dart';
import 'kick_generator_device_panel.dart';
import 'midi_delay_panel.dart';
import 'mood_fx_panels.dart';
import 'oscillator_device_panel.dart';
import 'phase_mod_synth_device_panel.dart';
import 'resonator_bank_panel.dart';
import 'routing_device_panel.dart';
import 'sampler_device_panel.dart';
import 'snare_generator_device_panel.dart';
import 'subtractive_synth_device_panel.dart';
import 'time_fx_panels.dart';
import 'wavetable_synth_device_panel.dart';

final Map<String, List<DeviceTabSpec>> generatedDevicePanelTabs = {
  'audio_receiver': RoutingDevicePanel.containerTabs,
  'bass_synth': BassSynthDevicePanel.containerTabs,
  'bitcrusher': BitcrusherFxPanel.containerTabs,
  'clap_generator': ClapGeneratorDevicePanel.containerTabs,
  'compressor': CompressorDevicePanel.containerTabs,
  'crash_generator': CrashGeneratorDevicePanel.containerTabs,
  'cymbal_generator': CymbalGeneratorDevicePanel.containerTabs,
  'distortion': DistortionFxPanel.containerTabs,
  'expander': ExpanderDevicePanel.containerTabs,
  'filter': FilterDevicePanel.containerTabs,
  'four_band_eq': FourBandEqDevicePanel.containerTabs,
  'frequency_shifter': FreqShifterDevicePanel.containerTabs,
  'gate': GateDevicePanel.containerTabs,
  'granular_formant_synth': GranularDevicePanel.containerTabs,
  'kick_generator': KickGeneratorDevicePanel.containerTabs,
  'limiter': LimiterDevicePanel.containerTabs,
  'midi_delay': MidiDelayPanel.containerTabs,
  'midi_receiver': RoutingDevicePanel.containerTabs,
  'phase_mod_synth': PhaseModSynthDevicePanel.containerTabs,
  'phaser': PhaserFxPanel.containerTabs,
  'resonator_bank': ResonatorBankPanel.containerTabs,
  'reverb': ReverbFxPanel.containerTabs,
  'simple_oscillator': OscillatorDevicePanel.containerTabs,
  'simple_sampler': SamplerDevicePanel.containerTabs,
  'snare_generator': SnareGeneratorDevicePanel.containerTabs,
  'stutter_fx': StutterFxPanel.containerTabs,
  'subtractive_synth': SubtractiveSynthDevicePanel.containerTabs,
  'tremolo': TremoloFxPanel.containerTabs,
  'wavetable_synth': WavetableSynthDevicePanel.containerTabs,
};
