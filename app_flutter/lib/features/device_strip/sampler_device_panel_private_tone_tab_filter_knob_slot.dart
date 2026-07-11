part of 'sampler_device_panel.dart';

extension _ToneTabFilterknobslot on _ToneTab {
  Widget _filterKnobSlot({
    required double maxKnob,
    required String label,
    required String paramId,
    required double value,
    required String displayValue,
    required ValueChanged<double> onChanged,
    Color accentColor = SamplerDevicePanel.accent,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final knobSize = math
            .min(constraints.maxHeight, constraints.maxWidth)
            .clamp(28.0, maxKnob);
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _knob(
              label: label,
              paramId: paramId,
              value: value,
              displayValue: displayValue,
              onChanged: onChanged,
              size: knobSize,
              labelGap: 1,
              accentColor: accentColor,
            ),
          ),
        );
      },
    );
  }
}
