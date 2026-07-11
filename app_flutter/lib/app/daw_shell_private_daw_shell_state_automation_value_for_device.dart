part of 'daw_shell.dart';

extension DawShellStateAutomationvaluefordeviceOperation on _DawShellState {
double _automationValueForDevice(DeviceSnapshot device, String paramId) {
    return switch (paramId) {
      'gain' => device.gain.clamp(0.0, 1.0),
      'pan' => device.pan.clamp(0.0, 1.0),
      'filterCutoff' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.filterCutoff,
          PhaseModSynthDeviceSnapshot d => d.filterCutoff,
          SamplerDeviceSnapshot d => d.filterCutoff,
          BassSynthDeviceSnapshot d => d.filterCutoff,
          _ => 1.0,
        })
            .clamp(0.0, 1.0),
      'filterQ' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.filterQ,
          PhaseModSynthDeviceSnapshot d => d.filterQ,
          SamplerDeviceSnapshot d => d.filterQ,
          _ => 0.5,
        })
            .clamp(0.0, 1.0),
      'attack' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.attack,
          PhaseModSynthDeviceSnapshot d => d.attack,
          SamplerDeviceSnapshot d => d.attack,
          BassSynthDeviceSnapshot d => d.attack,
          _ => 0.01,
        })
            .clamp(0.0, 1.0),
      'decay' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.decay,
          PhaseModSynthDeviceSnapshot d => d.decay,
          SamplerDeviceSnapshot d => d.decay,
          _ => 0.3,
        })
            .clamp(0.0, 1.0),
      'sustain' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.sustain,
          PhaseModSynthDeviceSnapshot d => d.sustain,
          SamplerDeviceSnapshot d => d.sustain,
          BassSynthDeviceSnapshot d => d.sustain,
          _ => 0.7,
        })
            .clamp(0.0, 1.0),
      'release' => (switch (device) {
          SubtractiveSynthDeviceSnapshot d => d.release,
          PhaseModSynthDeviceSnapshot d => d.release,
          SamplerDeviceSnapshot d => d.release,
          BassSynthDeviceSnapshot d => d.release,
          _ => 0.4,
        })
            .clamp(0.0, 1.0),
      'frequency' => (switch (device) {
          OscillatorDeviceSnapshot d => ((d.frequencyHz - 110.0) / 770.0),
          _ => 0.5,
        })
            .clamp(0.0, 1.0),
      _ => 0.5,
    };
  }
}
