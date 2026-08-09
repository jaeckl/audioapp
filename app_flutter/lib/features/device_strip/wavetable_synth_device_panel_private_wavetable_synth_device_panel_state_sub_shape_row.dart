part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateSubshaperow
    on _WavetableSynthDevicePanelState {
  /// Filter-style underline group — fixed 108×30 like SVG, not full-plate stretch.
  Widget _subShapeRow() {
    final selected = widget.device.wtSubShape.clamp(0, 2);
    const labels = ['SIN', 'TRI', 'SQR'];
    const groupW = 108.0;
    const groupH = DevicePanelTheme.modeRowHeight;

    return Align(
      alignment: Alignment.centerLeft,
      child: HorizontalGroupShell(
        width: groupW,
        height: groupH,
        value: selected.toDouble(),
        maxValue: 2,
        accent: WavetableSynthDevicePanel.accent,
        flat: true,
        modulationActive: widget.modulatedParams.contains('wtSubShape'),
        modulationAmount: widget.modulationAmounts['wtSubShape'] ?? 0.0,
        automationActive: widget.automatedParams.contains('wtSubShape'),
        connectModeActive: widget.connectModeLfoId != null,
        linkModeActive: widget.automationLinkActive,
        onModulationAssign: widget.onModulationAssign == null
            ? null
            : (a) => widget.onModulationAssign!('wtSubShape', a),
        onLinkTap: widget.onAutomationLinkTap == null
            ? null
            : () => widget.onAutomationLinkTap!('wtSubShape'),
        onAutomateRequest: widget.onAutomateParameter == null
            ? null
            : () => widget.onAutomateParameter!('wtSubShape'),
        child: Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      widget.onParameterChanged('wtSubShape', i.toDouble()),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: selected == i
                            ? WavetableSynthDevicePanel.accent
                                .withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                      Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color: selected == i
                                ? WavetableSynthDevicePanel.accent
                                : Colors.white.withValues(alpha: 0.46),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (selected == i)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 2,
                            color: WavetableSynthDevicePanel.accent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
