part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateLegacymixtab
    on _SubtractiveSynthDevicePanelState {
  Widget _legacyMixTab() {
    final knobScale = _knobSize * 0.78;
    final envKnob = _knobSize * 0.76;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _mixColumn(
                  title: 'PRE-FILTER',
                  row1: _knob(
                    label: 'HP Cut',
                    value: widget.device.preHpCutoff,
                    size: knobScale,
                    displayValue: widget.device.preHpCutoff <= 0.02
                        ? 'Off'
                        : SamplerDevicePanel.formatCutoffHz(
                            widget.device.preHpCutoff),
                    onChanged: (v) =>
                        widget.onParameterChanged('preHpCutoff', v),
                    paramId: 'preHpCutoff',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row2: _knob(
                    label: 'HP Res',
                    value: widget.device.preHpRes,
                    size: knobScale,
                    displayValue:
                        SamplerDevicePanel.formatQ(widget.device.preHpRes),
                    onChanged: (v) => widget.onParameterChanged('preHpRes', v),
                    paramId: 'preHpRes',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row3: _knob(
                    label: 'Drive',
                    value: widget.device.preDrive,
                    size: knobScale,
                    displayValue: SamplerDevicePanel.formatPercent(
                        widget.device.preDrive),
                    onChanged: (v) => widget.onParameterChanged('preDrive', v),
                    paramId: 'preDrive',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ),
                const SizedBox(width: 6),
                _mixColumn(
                  title: 'GLOBAL',
                  row1: _knob(
                    label: 'Pitch',
                    value: widget.device.globalPitch,
                    size: knobScale,
                    displayValue: SubtractiveSynthDevicePanel.formatGlobalPitch(
                        widget.device.globalPitch),
                    onChanged: (v) =>
                        widget.onParameterChanged('globalPitch', v),
                    paramId: 'globalPitch',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row2: _knob(
                    label: 'FB',
                    value: widget.device.mixFeedback,
                    size: knobScale,
                    displayValue: SamplerDevicePanel.formatPercent(
                        widget.device.mixFeedback),
                    onChanged: (v) =>
                        widget.onParameterChanged('mixFeedback', v),
                    paramId: 'mixFeedback',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  row3: _knob(
                    label: 'Vel',
                    value: widget.device.velocitySensitivity,
                    size: knobScale,
                    displayValue: SamplerDevicePanel.formatPercent(
                        widget.device.velocitySensitivity),
                    onChanged: (v) =>
                        widget.onParameterChanged('velocitySensitivity', v),
                    paramId: 'velocitySensitivity',
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _envelopePanel(
                  title: 'FEG',
                  maxKnob: envKnob,
                  attack: widget.device.filterAttack,
                  decay: widget.device.filterDecay,
                  sustain: widget.device.filterSustain,
                  release: widget.device.filterRelease,
                  onChanged: (id, v) => widget.onParameterChanged(id, v),
                  prefix: 'filter',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _envelopePanel(
                  title: 'AEG',
                  maxKnob: envKnob,
                  attack: widget.device.attack,
                  decay: widget.device.decay,
                  sustain: widget.device.sustain,
                  release: widget.device.release,
                  onChanged: widget.onParameterChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
