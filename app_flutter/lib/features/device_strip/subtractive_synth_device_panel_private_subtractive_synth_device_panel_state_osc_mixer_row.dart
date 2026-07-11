part of 'subtractive_synth_device_panel.dart';

extension _SubtractiveSynthDevicePanelStateOscmixerrow
    on _SubtractiveSynthDevicePanelState {
  Widget _oscMixerRow() {
    return SizedBox(
      height: 68,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: SubtractiveSynthDevicePanel.accent.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'SOURCE MIX',
              style: DevicePanelTheme.sectionLabel,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              height: 22,
              child: _borderlessDropdown<int>(
                value: widget.device.oscMixMode
                    .clamp(0, SubtractiveSynthDevicePanel._mixModes.length - 1),
                items: List.generate(
                  SubtractiveSynthDevicePanel._mixModes.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(SubtractiveSynthDevicePanel._mixModes[i]),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) {
                    widget.onParameterChanged('oscMixMode', v.toDouble());
                  }
                },
              ),
            ),
            const Spacer(),
            _knob(
              label: 'Mix',
              value: widget.device.oscMix,
              size: 48,
              labelGap: 0,
              displayValue:
                  SamplerDevicePanel.formatPercent(widget.device.oscMix),
              onChanged: (v) => widget.onParameterChanged('oscMix', v),
              paramId: 'oscMix',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            const SizedBox(width: 12),
            _knob(
              label: 'Noise',
              value: widget.device.noiseLevel,
              size: 48,
              labelGap: 0,
              displayValue:
                  SamplerDevicePanel.formatPercent(widget.device.noiseLevel),
              onChanged: (v) => widget.onParameterChanged('noiseLevel', v),
              paramId: 'noiseLevel',
              modulationAmounts: widget.modulationAmounts,
              connectModeLfoId: widget.connectModeLfoId,
              onModulationAssign: widget.onModulationAssign,
            ),
            const SizedBox(width: 12),
            _knob(
              label: 'Pitch',
              value: widget.device.globalPitch,
              size: 48,
              labelGap: 0,
              displayValue: SubtractiveSynthDevicePanel.formatGlobalPitch(
                  widget.device.globalPitch),
              onChanged: (v) => widget.onParameterChanged('globalPitch', v),
              paramId: 'globalPitch',
            ),
            const SizedBox(width: 12),
            _knob(
              label: 'Feedback',
              value: widget.device.mixFeedback,
              size: 48,
              labelGap: 0,
              displayValue:
                  SamplerDevicePanel.formatPercent(widget.device.mixFeedback),
              onChanged: (v) => widget.onParameterChanged('mixFeedback', v),
              paramId: 'mixFeedback',
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
