part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateAdsrrow
    on _WavetableSynthDevicePanelState {
  Widget _adsrRow({
    required double attack,
    required double decay,
    required double sustain,
    required double release,
    required void Function(String id, double value) onChanged,
    String prefix = '',
    double spacing = 6,
    double? knobSize,
    List<String> labels = const ['A', 'D', 'S', 'R'],
  }) {
    final size = knobSize ?? _knobSize * 0.78;
    String id(String n) =>
        prefix.isEmpty ? n : '$prefix${n[0].toUpperCase()}${n.substring(1)}';
    final values = [attack, decay, sustain, release];
    final names = ['attack', 'decay', 'sustain', 'release'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _knob(
                label: labels[i],
                value: values[i],
                size: size,
                labelGap: 2,
                displayValue: SamplerDevicePanel.formatPercent(values[i]),
                onChanged: (v) => onChanged(id(names[i]), v),
                paramId: id(names[i]),
                modulationAmounts: widget.modulationAmounts,
                connectModeLfoId: widget.connectModeLfoId,
                onModulationAssign: widget.onModulationAssign,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
