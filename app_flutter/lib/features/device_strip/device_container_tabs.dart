import 'device_tab_bar.dart';
import 'kick_generator_device_panel.dart';
import 'snare_generator_device_panel.dart';
import 'clap_generator_device_panel.dart';
import 'cymbal_generator_device_panel.dart';
import 'crash_generator_device_panel.dart';
import 'dynamics_fx_panels.dart';
import 'frequency_fx_panels.dart';
import 'oscillator_device_panel.dart';
import 'sampler_device_panel.dart';
import 'bass_synth_device_panel.dart';
import 'subtractive_synth_device_panel.dart';
import 'wavetable_synth_device_panel.dart';
import 'phase_mod_synth_device_panel.dart';
import 'mood_fx_panels.dart';
import 'resonator_bank_panel.dart';
import 'routing_device_panel.dart';

/// Device types register container header tabs here (icon + label).
abstract final class DeviceContainerTabs {
  static List<DeviceTabSpec> forDeviceType(String deviceType) {
    return switch (deviceType) {
      'simple_sampler' => SamplerDevicePanel.containerTabs,
      'simple_oscillator' => OscillatorDevicePanel.containerTabs,
      'bass_synth' => BassSynthDevicePanel.containerTabs,
      'subtractive_synth' => SubtractiveSynthDevicePanel.containerTabs,
      'wavetable_synth' => WavetableSynthDevicePanel.containerTabs,
      'kick_generator' => KickGeneratorDevicePanel.containerTabs,
      'snare_generator' => SnareGeneratorDevicePanel.containerTabs,
      'clap_generator' => ClapGeneratorDevicePanel.containerTabs,
      'cymbal_generator' => CymbalGeneratorDevicePanel.containerTabs,
      'crash_generator' => CrashGeneratorDevicePanel.containerTabs,
      'gate' => GateDevicePanel.containerTabs,
      'compressor' => CompressorDevicePanel.containerTabs,
      'expander' => ExpanderDevicePanel.containerTabs,
      'limiter' => LimiterDevicePanel.containerTabs,
      'phase_mod_synth' => PhaseModSynthDevicePanel.containerTabs,
      'filter' => FilterDevicePanel.containerTabs,
      'four_band_eq' => FourBandEqDevicePanel.containerTabs,
      'frequency_shifter' => FreqShifterDevicePanel.containerTabs,
      'resonator_bank' => ResonatorBankPanel.containerTabs,
      'audio_receiver' || 'midi_receiver' => RoutingDevicePanel.containerTabs,
      'bitcrusher' => BitcrusherFxPanel.containerTabs,
      'distortion' => DistortionFxPanel.containerTabs,
      'tremolo' => TremoloFxPanel.containerTabs,
      _ => const <DeviceTabSpec>[],
    };
  }
}
