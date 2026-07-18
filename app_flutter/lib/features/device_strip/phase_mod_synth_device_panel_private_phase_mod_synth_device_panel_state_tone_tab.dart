part of 'phase_mod_synth_device_panel.dart';

extension _PhaseModSynthDevicePanelStateTonetab
    on _PhaseModSynthDevicePanelState {
  Widget _toneTab() {
    final kSize = _knobSize;
    final mode = widget.device.filterMode.clamp(0, 5);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DeviceSectionCard(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'FILTER',
                    textAlign: TextAlign.center,
                    style: DevicePanelTheme.sectionLabel,
                  ),
                  const SizedBox(height: 4),
                  FilterModeSelector(
                    selectedIndex: mode,
                    parameterId: 'filterMode',
                    automated: widget.automatedParams.contains('filterMode'),
                    modulated: widget.modulatedParams.contains('filterMode'),
                    accentColor: PhaseModSynthDevicePanel.accent,
                    primaryOptions: const [
                      FilterModePrimaryOption(
                          index: 1, curve: FilterCurveMode.lowPass),
                      FilterModePrimaryOption(
                          index: 3, curve: FilterCurveMode.highPass),
                      FilterModePrimaryOption(
                          index: 2, curve: FilterCurveMode.bandPass),
                      FilterModePrimaryOption(
                          index: 0, curve: FilterCurveMode.lowPass),
                    ],
                    overflowOptions: const [
                      FilterModeOverflowOption(index: 4, label: 'HP24'),
                      FilterModeOverflowOption(index: 5, label: 'LP6'),
                    ],
                    onSelected: (index) => widget.onParameterChanged(
                        'filterMode', index.toDouble()),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: _knob(
                              label: 'Cutoff',
                              value: widget.device.filterCutoff,
                              size: kSize,
                              labelGap: 0,
                              displayValue: SamplerDevicePanel.formatCutoffHz(
                                widget.device.filterCutoff,
                              ),
                              onChanged: (v) =>
                                  widget.onParameterChanged('filterCutoff', v),
                              paramId: 'filterCutoff',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _knob(
                              label: 'Res',
                              value: widget.device.filterQ,
                              size: kSize,
                              labelGap: 0,
                              displayValue: SamplerDevicePanel.formatQ(
                                  widget.device.filterQ),
                              onChanged: (v) =>
                                  widget.onParameterChanged('filterQ', v),
                              paramId: 'filterQ',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _knob(
                              label: 'Env Amt',
                              value: widget.device.filterEnvAmount,
                              size: kSize,
                              labelGap: 0,
                              displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.filterEnvAmount,
                              ),
                              onChanged: (v) => widget.onParameterChanged(
                                  'filterEnvAmount', v),
                              paramId: 'filterEnvAmount',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: DeviceSectionCard(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Filter Env',
                    textAlign: TextAlign.center,
                    style: DevicePanelTheme.sectionLabel,
                  ),
                  const SizedBox(height: 2),
                  _adsrRow(
                    prefix: 'filter',
                    a: widget.device.filterAttack,
                    d: widget.device.filterDecay,
                    s: widget.device.filterSustain,
                    r: widget.device.filterRelease,
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
