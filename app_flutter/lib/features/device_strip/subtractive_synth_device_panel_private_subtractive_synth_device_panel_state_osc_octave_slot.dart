part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateOscoctaveslot
    on _SubtractiveSynthDevicePanelState {
  Widget _oscOctaveSlot({
    required double knobScale,
    required int octave,
    required String octaveParam,
  }) {
    return DraggableIntValueBox(
      value: octave,
      controlSize: knobScale,
      label: 'Oct',
      accentColor: SubtractiveSynthDevicePanel.accent,
      onChanged: (v) => widget.onParameterChanged(
        octaveParam,
        subtractiveNormFromOctave(v),
      ),
    );
  }
}
