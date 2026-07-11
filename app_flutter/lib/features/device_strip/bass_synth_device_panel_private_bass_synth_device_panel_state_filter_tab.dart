part of 'bass_synth_device_panel.dart';

extension _BassSynthDevicePanelStateFiltertab on _BassSynthDevicePanelState {
  Widget _filterTab() {
    final kSize = _knobSize;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── LEFT column: Filter curve + controls ──
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('FILTER CURVE', style: DevicePanelTheme.sectionLabel),
                  Expanded(
                    flex: 4,
                    child: DeviceSectionCard(
                      clipPreview: true,
                      padding: EdgeInsets.zero,
                      child: FilterPreview(
                        cutoffHz: DeviceParamFormatters.cutoffHzFromNormalized(
                          widget.device.filterCutoff,
                        ),
                        q: DeviceParamFormatters.qFromNormalized(
                          widget.device.bassFilterResonance,
                        ),
                        mode: FilterPreviewMode.lowPass,
                        accent: BassSynthDevicePanel.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('FILTER', style: DevicePanelTheme.sectionLabel),
                  Expanded(
                    flex: 5,
                    child: DeviceSectionCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _knob(
                            label: 'Cutoff',
                            value: widget.device.filterCutoff,
                            size: kSize,
                            displayValue: SamplerDevicePanel.formatCutoffHz(
                                widget.device.filterCutoff),
                            onChanged: (v) =>
                                widget.onParameterChanged('filterCutoff', v),
                            paramId: 'filterCutoff',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _knob(
                            label: 'Res',
                            value: widget.device.bassFilterResonance,
                            size: kSize,
                            displayValue: SamplerDevicePanel.formatQ(
                                widget.device.bassFilterResonance),
                            onChanged: (v) => widget.onParameterChanged(
                                'bassFilterResonance', v),
                            paramId: 'bassFilterResonance',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _knob(
                            label: 'Env Amt',
                            value: widget.device.filterEnvAmount,
                            size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.filterEnvAmount),
                            onChanged: (v) =>
                                widget.onParameterChanged('filterEnvAmount', v),
                            paramId: 'filterEnvAmount',
                            modulationAmounts: widget.modulationAmounts,
                            connectModeLfoId: widget.connectModeLfoId,
                            onModulationAssign: widget.onModulationAssign,
                          ),
                          _knob(
                            label: 'Decay',
                            value: widget.device.filterDecay,
                            size: kSize,
                            displayValue: SamplerDevicePanel.formatPercent(
                                widget.device.filterDecay),
                            onChanged: (v) =>
                                widget.onParameterChanged('filterDecay', v),
                            paramId: 'filterDecay',
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
          ),

          // ── RIGHT column: SATURATION (Drive + Squash) ──
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('SATURATION'),
                Expanded(
                  child: _panelBox(
                    color: const Color(0xFF16161E),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _knob(
                          label: 'Drive',
                          value: widget.device.bassDrive,
                          size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(
                              widget.device.bassDrive),
                          onChanged: (v) =>
                              widget.onParameterChanged('bassDrive', v),
                          paramId: 'bassDrive',
                          modulationAmounts: widget.modulationAmounts,
                          connectModeLfoId: widget.connectModeLfoId,
                          onModulationAssign: widget.onModulationAssign,
                        ),
                        const SizedBox(height: 12),
                        _knob(
                          label: 'Squash',
                          value: widget.device.bassSquash,
                          size: kSize,
                          displayValue: SamplerDevicePanel.formatPercent(
                              widget.device.bassSquash),
                          onChanged: (v) =>
                              widget.onParameterChanged('bassSquash', v),
                          paramId: 'bassSquash',
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
        ],
      ),
    );
  }
}
