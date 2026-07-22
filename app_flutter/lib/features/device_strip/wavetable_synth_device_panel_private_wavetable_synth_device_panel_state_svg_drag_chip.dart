part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateSvgdragchip
    on _WavetableSynthDevicePanelState {
  /// SVG value chip — label top-left, value bottom-right (not ValueDragBox).
  Widget _svgDragChip({
    required String label,
    required double valueNorm,
    required List<double> values,
    required String Function(double norm) format,
    required String paramId,
    required ValueChanged<double> onChanged,
    int resetIndex = 0,
    double height = 42,
    double dragPixelsPerStep = 12,
  }) {
    final valueCount = values.length;
    final idx = ValueDragBox.normToIndex(valueNorm, valueCount);
    final display = format(valueNorm);

    double dragStartY = 0;
    int dragStartIdx = idx;

    final chip = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 72.0;
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : height;
        return deviceAutomationSpinner(
          paramId: paramId,
          width: w,
          height: h,
          accentColor: WavetableSynthDevicePanel.accent,
          borderAlpha: 0,
          modulatedParams: widget.modulatedParams,
          automatedParams: widget.automatedParams,
          modulationAmounts: widget.modulationAmounts,
          connectModeLfoId: widget.connectModeLfoId,
          onModulationAssign: widget.onModulationAssign,
          automationLinkActive: widget.automationLinkActive,
          onAutomationLinkTap: widget.onAutomationLinkTap,
          onAutomateParameter: widget.onAutomateParameter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (d) {
              dragStartY = d.localPosition.dy;
              dragStartIdx = idx;
            },
            onVerticalDragUpdate: (d) {
              final delta =
                  ((dragStartY - d.localPosition.dy) / dragPixelsPerStep)
                      .round();
              final nextIdx = (dragStartIdx + delta).clamp(0, valueCount - 1);
              if (nextIdx != idx) {
                onChanged(ValueDragBox.indexToNorm(nextIdx, valueCount));
              }
            },
            onDoubleTap: () =>
                onChanged(ValueDragBox.indexToNorm(resetIndex, valueCount)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF14141C),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF6A6A78),
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        display,
                        style: const TextStyle(
                          color: Color(0xFFE8E8F0),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return SizedBox(height: height, child: chip);
  }
}
