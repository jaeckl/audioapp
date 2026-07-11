part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateFiltertab
    on _WavetableSynthDevicePanelState {
  Widget _filterTab() {
    final mode = widget.device.filterMode.clamp(
      0,
      WavetableSynthDevicePanel._filterTypes.length - 1,
    );
    final knobScale = _knobSize * 0.76;

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 240.0;
          final previewHeight =
              (availableHeight * 0.36).clamp(56.0, 82.0).toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DevicePreviewFrame(
                height: previewHeight,
                child: FilterPreview(
                  cutoffHz: _filterCutoffHz(widget.device.filterCutoff),
                  q: _filterQ(widget.device.filterResonance),
                  mode: _filterPreviewMode(mode),
                  accent: WavetableSynthDevicePanel.accent,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: DeviceSectionCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
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
                        accentColor: WavetableSynthDevicePanel.accent,
                        onSelected: (index) => widget.onParameterChanged(
                            'filterMode', index.toDouble()),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: _knobGridRow(
                          knobScale: knobScale,
                          slots: [
                            _knob(
                              label: 'Cutoff',
                              value: widget.device.filterCutoff,
                              size: knobScale,
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
                              value: widget.device.filterResonance,
                              size: knobScale,
                              displayValue: SamplerDevicePanel.formatQ(
                                  widget.device.filterResonance),
                              onChanged: (v) => widget.onParameterChanged(
                                  'filterResonance', v),
                              paramId: 'filterResonance',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                            _knob(
                              label: 'Env Amt',
                              value: widget.device.filterEnvAmount,
                              size: knobScale,
                              displayValue: SamplerDevicePanel.formatPercent(
                                  widget.device.filterEnvAmount),
                              onChanged: (v) => widget.onParameterChanged(
                                  'filterEnvAmount', v),
                              paramId: 'filterEnvAmount',
                              modulationAmounts: widget.modulationAmounts,
                              connectModeLfoId: widget.connectModeLfoId,
                              onModulationAssign: widget.onModulationAssign,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
