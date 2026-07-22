part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateFiltertab
    on _WavetableSynthDevicePanelState {
  /// TONE — same Filter-device chrome: hero curve + plate with
  /// embedded underline mode group (30px) then Cut/Res/Drive + FEG.
  Widget _filterTab() {
    final mode = widget.device.filterMode.clamp(
      0,
      WavetableSynthDevicePanel._filterTypes.length - 1,
    );
    final knob = _knobSize * 0.78;
    final fegKnob = _knobSize * 0.72;

    return FilterSectionLayout(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      preview: FilterPreview(
        cutoffHz: DeviceParamFormatters.cutoffHzFromNormalized(
          widget.device.filterCutoff,
        ),
        q: DeviceParamFormatters.qFromNormalized(
          widget.device.filterResonance,
        ),
        mode: FilterPreviewMode.values[mode.clamp(0, 3)],
        accent: WavetableSynthDevicePanel.accent,
      ),
      modeSelector: FilterModeSelector(
        selectedIndex: mode,
        parameterId: 'filterMode',
        automated: widget.automatedParams.contains('filterMode'),
        modulated: widget.modulatedParams.contains('filterMode'),
        modulationAmount: widget.modulationAmounts['filterMode'] ?? 0.0,
        accentColor: WavetableSynthDevicePanel.accent,
        embeddedInWell: true,
        height: DevicePanelTheme.modeRowHeight,
        connectModeActive: widget.connectModeLfoId != null,
        linkModeActive: widget.automationLinkActive,
        onModulationAssign: widget.onModulationAssign == null
            ? null
            : (a) => widget.onModulationAssign!('filterMode', a),
        onLinkTap: widget.onAutomationLinkTap == null
            ? null
            : () => widget.onAutomationLinkTap!('filterMode'),
        onAutomateRequest: widget.onAutomateParameter == null
            ? null
            : () => widget.onAutomateParameter!('filterMode'),
        onSelected: (index) =>
            widget.onParameterChanged('filterMode', index.toDouble()),
      ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _knob(
                      label: 'CUTOFF',
                      value: widget.device.filterCutoff,
                      size: knob,
                      displayValue: SamplerDevicePanel.formatCutoffHz(
                          widget.device.filterCutoff),
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _knob(
                      label: 'RES',
                      value: widget.device.filterResonance,
                      size: knob,
                      displayValue: SamplerDevicePanel.formatQ(
                          widget.device.filterResonance),
                      onChanged: (v) =>
                          widget.onParameterChanged('filterResonance', v),
                      paramId: 'filterResonance',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _knob(
                      label: 'DRIVE',
                      value: widget.device.filterDrive,
                      size: knob,
                      displayValue: SamplerDevicePanel.formatPercent(
                          widget.device.filterDrive),
                      onChanged: (v) =>
                          widget.onParameterChanged('filterDrive', v),
                      paramId: 'filterDrive',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'FILTER ENVELOPE',
            style: DevicePanelTheme.sectionLabel,
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 72,
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _knob(
                      label: 'AMOUNT',
                      value: widget.device.filterEnvAmount,
                      size: fegKnob,
                      displayValue: SamplerDevicePanel.formatPercent(
                          widget.device.filterEnvAmount),
                      onChanged: (v) =>
                          widget.onParameterChanged('filterEnvAmount', v),
                      paramId: 'filterEnvAmount',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _adsrRow(
                    attack: widget.device.filterAttack,
                    decay: widget.device.filterDecay,
                    sustain: widget.device.filterSustain,
                    release: widget.device.filterRelease,
                    spacing: 2,
                    knobSize: fegKnob,
                    labels: const [
                      'ATTACK',
                      'DECAY',
                      'SUSTAIN',
                      'RELEASE'
                    ],
                    onChanged: widget.onParameterChanged,
                    prefix: 'filter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
