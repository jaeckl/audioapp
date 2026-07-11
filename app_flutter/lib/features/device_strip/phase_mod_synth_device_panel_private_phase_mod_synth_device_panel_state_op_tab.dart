part of 'phase_mod_synth_device_panel.dart';

extension _PhaseModSynthDevicePanelStateOptab
    on _PhaseModSynthDevicePanelState {
  Widget _opTab() {
    final kSize = _knobSize;
    final accent = PhaseModSynthDevicePanel.accent;
    final op = _selectedOperator;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: OP selector, Waveform, Level
          Expanded(
            flex: 6,
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  // OP Buttons
                  Expanded(
                    flex: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) {
                        final selected = op == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedOperator = i),
                          child: Container(
                            width: 32,
                            height: 24,
                            decoration: BoxDecoration(
                              color: selected
                                  ? accent.withValues(alpha: 0.28)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: selected
                                    ? accent.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'OP${i + 1}',
                                style: TextStyle(
                                  color: selected ? accent : Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const VerticalDivider(color: Colors.white10, width: 12),
                  // Waveform dropdown
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: _borderlessDropdown<double>(
                        label: 'Wave',
                        value: _opParam(op, 'wave'),
                        items: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        itemLabels: const ['Sine', 'Tri', 'Saw', 'Sq', 'Noise'],
                        onChanged: (v) => widget.onParameterChanged(
                          _opParamId(op, 'Wave'),
                          v,
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(color: Colors.white10, width: 12),
                  // Level (Output mix / modulator strength of this operator)
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: _knob(
                        label: 'Level',
                        value: _opParam(op, 'level'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(
                            _opParam(op, 'level')),
                        onChanged: (v) => widget.onParameterChanged(
                          _opParamId(op, 'Level'),
                          v,
                        ),
                        paramId: _opParamId(op, 'Level'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Row 2: Ratio, Fine, VelSense, KeyTrack
          Expanded(
            flex: 6,
            child: _panelBox(
              color: const Color(0xFF16161E),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _draggableRatioBox(
                    opIndex: op,
                    value: _opParam(op, 'ratio'),
                    paramId: _opParamId(op, 'Ratio'),
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'Ratio'),
                      v,
                    ),
                  ),
                  _knob(
                    label: 'Fine',
                    value: _opParam(op, 'fine'),
                    size: kSize,
                    labelGap: 0,
                    displayValue:
                        '${((_opParam(op, 'fine') - 0.5) * 100).round()} ct',
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'Fine'),
                      v,
                    ),
                    paramId: _opParamId(op, 'Fine'),
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Vel Sense',
                    value: _opParam(op, 'velSense'),
                    size: kSize,
                    labelGap: 0,
                    displayValue: SamplerDevicePanel.formatPercent(
                        _opParam(op, 'velSense')),
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'VelSense'),
                      v,
                    ),
                    paramId: _opParamId(op, 'VelSense'),
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                  _knob(
                    label: 'Key Track',
                    value: _opParam(op, 'keyTrack'),
                    size: kSize,
                    labelGap: 0,
                    displayValue: SamplerDevicePanel.formatPercent(
                        _opParam(op, 'keyTrack')),
                    onChanged: (v) => widget.onParameterChanged(
                      _opParamId(op, 'KeyTrack'),
                      v,
                    ),
                    paramId: _opParamId(op, 'KeyTrack'),
                    modulationAmounts: widget.modulationAmounts,
                    connectModeLfoId: widget.connectModeLfoId,
                    onModulationAssign: widget.onModulationAssign,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Row 3: Unique Destination Influence Matrix (in place of ADSR matrix!)
          Expanded(
            flex: 7,
            child: _panelBox(
              color: const Color(0xFF1A1A24),
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'OP${op + 1} Phase Modulation Drives',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _knob(
                        label: 'to OP1',
                        value: _opParam(op, 'attack'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(
                            _opParam(op, 'attack')),
                        onChanged: (v) => widget.onParameterChanged(
                            _opParamId(op, 'Attack'), v),
                        paramId: _opParamId(op, 'Attack'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                      _knob(
                        label: 'to OP2',
                        value: _opParam(op, 'decay'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(
                            _opParam(op, 'decay')),
                        onChanged: (v) => widget.onParameterChanged(
                            _opParamId(op, 'Decay'), v),
                        paramId: _opParamId(op, 'Decay'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                      _knob(
                        label: 'to OP3',
                        value: _opParam(op, 'sustain'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(
                            _opParam(op, 'sustain')),
                        onChanged: (v) => widget.onParameterChanged(
                            _opParamId(op, 'Sustain'), v),
                        paramId: _opParamId(op, 'Sustain'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                      _knob(
                        label: 'to OP4',
                        value: _opParam(op, 'release'),
                        size: kSize,
                        labelGap: 0,
                        displayValue: SamplerDevicePanel.formatPercent(
                            _opParam(op, 'release')),
                        onChanged: (v) => widget.onParameterChanged(
                            _opParamId(op, 'Release'), v),
                        paramId: _opParamId(op, 'Release'),
                        modulationAmounts: widget.modulationAmounts,
                        connectModeLfoId: widget.connectModeLfoId,
                        onModulationAssign: widget.onModulationAssign,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
