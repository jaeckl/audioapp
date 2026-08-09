part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateSuboctaveslot
    on _WavetableSynthDevicePanelState {
  Widget _subOctaveSlot({
    required int value,
    required double knobScale,
  }) {
    const min = 0;
    const max = 2;
    final accent = WavetableSynthDevicePanel.accent;
    final muted = accent.withValues(alpha: 0.55);
    final display = WavetableSynthDevicePanel.subOctaveLabel(value.clamp(min, max));
    final labelSize = knobScale >= DeviceKnobSizes.strip ? 10.0 : 9.0;

    void bump(int delta) {
      final next = (value + delta).clamp(min, max);
      if (next != value) {
        widget.onParameterChanged('wtSubOctave', next.toDouble());
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: knobScale + 4,
          width: 46,
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => bump(1),
                  child: Icon(Icons.keyboard_arrow_up_rounded,
                      size: 14, color: muted),
                ),
              ),
              Text(
                display,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => bump(-1),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: muted),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 3),
        Text(
          'OCTAVE',
          style: TextStyle(
            color: Colors.white54,
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
