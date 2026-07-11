part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateOsctab
    on _WavetableSynthDevicePanelState {
  Widget _oscTab() {
    final knobScale = _knobSize * 0.76;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 260.0;
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : WavetableSynthDevicePanel.designWidth;

          final gap = availableWidth < 360 ? 4.0 : 6.0;
          final previewHeight =
              (availableHeight * 0.48).clamp(86.0, 126.0).toDouble();
          final unisonWidth =
              (availableWidth * 0.28).clamp(92.0, 118.0).toDouble();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: previewHeight,
                      child: _panelBox(
                        padding: EdgeInsets.zero,
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
                    SizedBox(height: gap),
                    Expanded(
                      child: _panelBox(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 5),
                        child: _knobGridRow(
                          knobScale: knobScale,
                          slots: [
                            _knob(
                              label: 'Position',
                              value: widget.device.wtPosition,
                              size: knobScale,
                              displayValue: SamplerDevicePanel.formatPercent(
                                  widget.device.wtPosition),
                              onChanged: (v) =>
                                  widget.onParameterChanged('wtPosition', v),
                              paramId: 'wtPosition',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                            _knob(
                              label: 'Octave',
                              value: widget.device.wtOctave,
                              size: knobScale,
                              displayValue:
                                  _formatOctave(widget.device.wtOctave),
                              onChanged: (v) =>
                                  widget.onParameterChanged('wtOctave', v),
                              paramId: 'wtOctave',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                            _knob(
                              label: 'Semi',
                              value: widget.device.wtSemitone,
                              size: knobScale,
                              displayValue:
                                  _formatSemitone(widget.device.wtSemitone),
                              onChanged: (v) =>
                                  widget.onParameterChanged('wtSemitone', v),
                              paramId: 'wtSemitone',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                            _knob(
                              label: 'Fine',
                              value: widget.device.wtFine,
                              size: knobScale,
                              displayValue: _formatFine(widget.device.wtFine),
                              onChanged: (v) =>
                                  widget.onParameterChanged('wtFine', v),
                              paramId: 'wtFine',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: gap),
              SizedBox(
                width: unisonWidth,
                child: _unisonColumn(knobScale: knobScale),
              ),
            ],
          );
        },
      ),
    );
  }
}
