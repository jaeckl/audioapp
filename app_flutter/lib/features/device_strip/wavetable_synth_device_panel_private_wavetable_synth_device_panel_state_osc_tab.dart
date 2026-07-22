part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateOsctab
    on _WavetableSynthDevicePanelState {
  /// SOURCE v2 matrix — clip everything so chips/knobs never paint outside.
  Widget _oscTab() {
    final knob = _knobSize * 0.80;
    final shapeKnob = _knobSize * 0.74;

    return ColoredBox(
      color: const Color(0xFF07070A),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;
            const gap = 6.0;
            // SVG: top ~154 / bottom ~108 of 280 face ≈ 0.55 / 0.40
            final bottomH = (h * 0.39).clamp(102.0, 114.0);
            final topH = h - bottomH - gap;
            final rightW = (w * 0.36).clamp(140.0, 156.0);
            final leftW = w - rightW - gap;
            // Pitch chips are 42 tall (SVG); leave rest for wave.
            const pitchH = 42.0;

            return Column(
              children: [
                SizedBox(
                  height: topH,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: leftW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: WavetableWaveformPreview(
                                  accent: WavetableSynthDevicePanel.accent,
                                  showLabel: true,
                                  label: widget.device.wavetableId,
                                  onTap: widget.onOpenWavetableLibrary,
                                  wavetableId: widget.device.wavetableId,
                                  wtPosition: widget.device.wtPosition,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(height: pitchH, child: _pitchRow()),
                          ],
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: rightW,
                        child: ClipRect(
                          child: _waveShapePlate(knobScale: shapeKnob),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: gap),
                SizedBox(
                  height: bottomH,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: leftW,
                        child: ClipRect(
                          child: _subNoiseWell(knobScale: knob),
                        ),
                      ),
                      const SizedBox(width: gap),
                      SizedBox(
                        width: rightW,
                        child: ClipRect(
                          child: _unisonColumn(knobScale: knob),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
