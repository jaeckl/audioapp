part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStatePitchrow
    on _WavetableSynthDevicePanelState {
  /// SVG pitch row under wave — label top-left, value bottom-right.
  Widget _pitchRow() {
    return Row(
      children: [
        Expanded(
          child: _svgDragChip(
            label: 'OCTAVE',
            valueNorm: widget.device.wtOctave,
            values: List<double>.generate(5, (i) => i / 4.0),
            format: _formatOctave,
            paramId: 'wtOctave',
            resetIndex: 2,
            onChanged: (n) => widget.onParameterChanged('wtOctave', n),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _svgDragChip(
            label: 'SEMI',
            valueNorm: widget.device.wtSemitone,
            values: List<double>.generate(49, (i) => i / 48.0),
            format: _formatSemitone,
            paramId: 'wtSemitone',
            resetIndex: 24,
            onChanged: (n) => widget.onParameterChanged('wtSemitone', n),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 6,
          child: _svgDragChip(
            label: 'FINE',
            valueNorm: widget.device.wtFine,
            values: List<double>.generate(101, (i) => i / 100.0),
            format: _formatFine,
            paramId: 'wtFine',
            resetIndex: 50,
            onChanged: (n) => widget.onParameterChanged('wtFine', n),
          ),
        ),
      ],
    );
  }
}
