part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateOscbank
    on _SubtractiveSynthDevicePanelState {
  Widget _oscBank({
    required double shape,
    required String shapeParam,
    required double semi,
    required String semiParam,
    required double octaveNorm,
    required String octaveParam,
    required double syncValue,
    required String syncParam,
    required String syncDisplay,
    required double knobScale,
    double? detuneValue,
    String? detuneParam,
    String? detuneDisplay,
  }) {
    final octave = subtractiveOctaveFromNorm(octaveNorm);
    final hasDetune =
        detuneValue != null && detuneParam != null && detuneDisplay != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 68,
          child: _panelBox(
            variant: PanelVariant.screen,
            padding: EdgeInsets.zero,
            child: SubtractiveWaveformPreview(
              shape: shape,
              accent: SubtractiveSynthDevicePanel.accent,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _oscKnobGridRow(
            knobScale: knobScale,
            slots: [
              _knob(
                label: 'Shape',
                value: shape,
                size: knobScale,
                displayValue: subtractiveShapeLabel(shape),
                onChanged: (v) => widget.onParameterChanged(shapeParam, v),
                paramId: shapeParam,
                modulationAmounts: widget.modulationAmounts,
                connectModeLfoId: widget.connectModeLfoId,
                onModulationAssign: widget.onModulationAssign,
              ),
              _oscOctaveSlot(
                knobScale: knobScale,
                octave: octave,
                octaveParam: octaveParam,
              ),
              _knob(
                label: 'Semi',
                value: semi,
                size: knobScale,
                displayValue: '${(semi * 11).round()}',
                onChanged: (v) => widget.onParameterChanged(semiParam, v),
                paramId: semiParam,
                modulationAmounts: widget.modulationAmounts,
                connectModeLfoId: widget.connectModeLfoId,
                onModulationAssign: widget.onModulationAssign,
              ),
              hasDetune
                  ? _knob(
                      label: 'Fine',
                      value: detuneValue,
                      size: knobScale,
                      displayValue: detuneDisplay,
                      onChanged: (v) =>
                          widget.onParameterChanged(detuneParam, v),
                      paramId: detuneParam,
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    )
                  : null,
              _knob(
                label: 'Sync',
                value: syncValue,
                size: knobScale,
                displayValue: syncDisplay,
                onChanged: (v) => widget.onParameterChanged(syncParam, v),
                paramId: syncParam,
                modulationAmounts: widget.modulationAmounts,
                connectModeLfoId: widget.connectModeLfoId,
                onModulationAssign: widget.onModulationAssign,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
