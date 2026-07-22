part of 'wavetable_synth_device_panel.dart';

extension _WavetableSynthDevicePanelStateWaveshapeplate
    on _WavetableSynthDevicePanelState {
  /// SVG top-right: Pos|Warp knobs, Mode + Phase/Rnd chips (SVG chip style).
  Widget _waveShapePlate({required double knobScale}) {
    final mode = widget.device.wtWarpMode.clamp(0, 4);
    final ph = (widget.device.wtPhase * 100).round();
    final rnd = (widget.device.wtPhaseRandom * 100).round();

    return _panelBox(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _knob(
                      label: 'POSITION',
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
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _knob(
                      label: 'WARP',
                      value: widget.device.wtWarp,
                      size: knobScale,
                      displayValue: SamplerDevicePanel.formatPercent(
                          widget.device.wtWarp),
                      onChanged: (v) =>
                          widget.onParameterChanged('wtWarp', v),
                      paramId: 'wtWarp',
                      modulationAmounts: widget.modulationAmounts,
                      connectModeLfoId: widget.connectModeLfoId,
                      onModulationAssign: widget.onModulationAssign,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 42,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _svgDragChip(
                    label: 'WARP MODE',
                    valueNorm: mode / 4.0,
                    values: const [0, 1, 2, 3, 4],
                    format: (n) => WavetableSynthDevicePanel
                        .warpModeLabels[(n * 4).round().clamp(0, 4)],
                    paramId: 'wtWarpMode',
                    onChanged: (n) => widget.onParameterChanged(
                        'wtWarpMode', (n * 4).round().toDouble()),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 5,
                  child: _svgDragChip(
                    label: 'PHASE / RND',
                    valueNorm: widget.device.wtPhase,
                    values: List<double>.generate(21, (i) => i / 20.0),
                    format: (_) => '$ph / $rnd%',
                    paramId: 'wtPhase',
                    onChanged: (n) =>
                        widget.onParameterChanged('wtPhase', n),
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
