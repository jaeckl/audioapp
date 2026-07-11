part of 'bass_synth_device_panel.dart';

extension _BassSynthDevicePanelStateAmpenvelopepreview
    on _BassSynthDevicePanelState {
  Widget _ampEnvelopePreview() {
    return SamplerEnvelopePreview(
      attack: widget.device.attack,
      decay: widget.device.attack * 0.3 + 0.02, // decay ~related to attack feel
      sustain: widget.device.sustain,
      release: widget.device.release,
      accent: BassSynthDevicePanel.accent,
      label: 'AMP',
    );
  }
}
