part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateTonetab
    on _SubtractiveSynthDevicePanelState {
  Widget _toneTab() {
    final mode = widget.device.filterMode
        .clamp(0, SubtractiveSynthDevicePanel._filterTypes.length - 1);
    final shaperMode = widget.device.filterShaperMode
        .clamp(0, SubtractiveSynthDevicePanel._shaperModes.length - 1);
    final filterKnob = _knobSize;
    final colorKnob = _knobSize * 0.86;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: DevicePanelTheme.previewHeroHeight,
            child: DevicePreviewFrame(
              height: DevicePanelTheme.previewHeroHeight,
              child: SubtractiveFilterPreview(
                filterMode: mode,
                filterCutoff: widget.device.filterCutoff,
                filterQ: widget.device.filterQ,
                accent: SubtractiveSynthDevicePanel.accent,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: _panelBox(
                    variant: PanelVariant.elevated,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilterModeSelector(
                          selectedIndex: mode,
                          parameterId: 'filterMode',
                          automated:
                              widget.automatedParams.contains('filterMode'),
                          modulated:
                              widget.modulatedParams.contains('filterMode'),
                          accentColor: SubtractiveSynthDevicePanel.accent,
                          overflowOptions: const [
                            FilterModeOverflowOption(index: 4, label: 'FB'),
                            FilterModeOverflowOption(index: 5, label: 'LP 24'),
                          ],
                          onSelected: (index) => widget.onParameterChanged(
                              'filterMode', index.toDouble()),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _filterKeyTrackToggle(),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 22),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 10,
                                      color: widget.device.filterKeyTrack >
                                              0.001
                                          ? SubtractiveSynthDevicePanel.accent
                                          : Colors.white24,
                                    ),
                                  ),
                                  _knob(
                                    label: 'Cutoff',
                                    value: widget.device.filterCutoff,
                                    size: filterKnob,
                                    labelGap: 1,
                                    displayValue:
                                        SamplerDevicePanel.formatCutoffHz(
                                      widget.device.filterCutoff,
                                    ),
                                    onChanged: (v) => widget.onParameterChanged(
                                        'filterCutoff', v),
                                    paramId: 'filterCutoff',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                  _knob(
                                    label: 'Res',
                                    value: widget.device.filterQ,
                                    size: filterKnob,
                                    labelGap: 1,
                                    displayValue: SamplerDevicePanel.formatQ(
                                        widget.device.filterQ),
                                    onChanged: (v) =>
                                        widget.onParameterChanged('filterQ', v),
                                    paramId: 'filterQ',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                  _knob(
                                    label: 'Env',
                                    value: widget.device.filterEnvAmount,
                                    size: filterKnob,
                                    labelGap: 1,
                                    displayValue:
                                        SamplerDevicePanel.formatPercent(
                                      widget.device.filterEnvAmount,
                                    ),
                                    onChanged: (v) => widget.onParameterChanged(
                                        'filterEnvAmount', v),
                                    paramId: 'filterEnvAmount',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                  _knob(
                                    label: 'FM',
                                    value: widget.device.filterFm,
                                    size: filterKnob,
                                    labelGap: 1,
                                    displayValue:
                                        SamplerDevicePanel.formatPercent(
                                      widget.device.filterFm,
                                    ),
                                    onChanged: (v) => widget.onParameterChanged(
                                        'filterFm', v),
                                    paramId: 'filterFm',
                                    modulationAmounts: widget.modulationAmounts,
                                    connectModeLfoId: widget.connectModeLfoId,
                                    onModulationAssign:
                                        widget.onModulationAssign,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 1,
                  child: _panelBox(
                    variant: PanelVariant.subtle,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'COLOR',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Center(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _knob(
                                      label: 'Drive',
                                      value: widget.device.filterDrive,
                                      size: colorKnob,
                                      labelGap: 1,
                                      displayValue:
                                          SamplerDevicePanel.formatPercent(
                                              widget.device.filterDrive),
                                      onChanged: (v) => widget
                                          .onParameterChanged('filterDrive', v),
                                      paramId: 'filterDrive',
                                      modulationAmounts:
                                          widget.modulationAmounts,
                                      connectModeLfoId: widget.connectModeLfoId,
                                      onModulationAssign:
                                          widget.onModulationAssign,
                                    ),
                                    _knob(
                                      label: 'Shaper',
                                      value: widget.device.filterShaper,
                                      size: colorKnob,
                                      labelGap: 1,
                                      displayValue:
                                          SamplerDevicePanel.formatPercent(
                                              widget.device.filterShaper),
                                      onChanged: (v) =>
                                          widget.onParameterChanged(
                                              'filterShaper', v),
                                      paramId: 'filterShaper',
                                      modulationAmounts:
                                          widget.modulationAmounts,
                                      connectModeLfoId: widget.connectModeLfoId,
                                      onModulationAssign:
                                          widget.onModulationAssign,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: SizedBox(
                            width: 52,
                            height: 22,
                            child: _borderlessDropdown<int>(
                              value: shaperMode,
                              items: List.generate(
                                SubtractiveSynthDevicePanel._shaperModes.length,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    SubtractiveSynthDevicePanel._shaperModes[i],
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ),
                              ),
                              onChanged: (v) {
                                if (v != null) {
                                  widget.onParameterChanged(
                                      'filterShaperMode', v.toDouble());
                                }
                              },
                            ),
                          ),
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
