part of 'spectral_loud_split_panel.dart';

extension SpectralLoudSplitPanelBandRow on SpectralLoudSplitPanel {
  Widget bandRow({
    required int bandIndex,
    required String label,
    required bool expanded,
    required double level,
  }) {
    final gain = device.bandGainAt(bandIndex);
    final solo = device.bandSoloAt(bandIndex);
    final gainParamId = 'band${bandIndex}Gain';
    final soloParamId = 'band${bandIndex}Solo';
    final bandColor = DeviceStripTheme.spectralLoudBandColor(bandIndex);

    // daw_elements elevated panel (#16161E): solid fill, no border, no tint.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeviceStripTheme.panelElevated,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: SpectralLoudSplitLayout.soloLeftPad),
          GestureDetector(
            onTap: () => onChanged(soloParamId, solo ? 0 : 1),
            child: Container(
              width: SpectralLoudSplitLayout.solo,
              height: SpectralLoudSplitLayout.solo,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: solo
                    ? bandColor.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'S',
                style: TextStyle(
                  color: solo ? bandColor : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: SpectralLoudSplitLayout.soloToggleGap),
          SplitBranchToggleButton(
            label: label,
            active: expanded,
            accentColor: bandColor,
            centerBody: true,
            onPressed: () => onToggleBand(bandIndex),
          ),
          const SizedBox(width: SpectralLoudSplitLayout.gap),
          deviceAutomationKnob(
            label: 'Gain',
            value: (gain / 2).clamp(0.0, 1.0),
            displayValue: '${(gain * 100).round()}%',
            onChanged: (v) => onChanged(gainParamId, v * 2),
            paramId: gainParamId,
            deviceId: device.id,
            modulatedParams: modulatedParams,
            automatedParams: automatedParams,
            modulationAmounts: modulationAmounts,
            lfos: lfos,
            modEdges: modEdges,
            connectModeLfoId: connectModeLfoId,
            onModulationAssign: onModulationAssign,
            automationLinkActive: automationLinkActive,
            onAutomationLinkTap: onAutomationLinkTap,
            onAutomateParameter: onAutomateParameter,
            accentColor: bandColor,
            size: DeviceKnobSizes.compact,
          ),
          const SizedBox(width: SpectralLoudSplitLayout.gap),
          SizedBox(
            width: SpectralLoudSplitLayout.vu,
            height: 44,
            child: DeviceVuMeter(active: level > 0.01 || solo, level: level),
          ),
        ],
      ),
    );
  }
}
