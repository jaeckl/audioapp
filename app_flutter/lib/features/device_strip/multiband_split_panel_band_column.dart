part of 'multiband_split_panel.dart';

extension MultibandSplitPanelBandColumn on MultibandSplitPanel {
  Widget bandColumn({
    required int bandIndex,
    required String label,
    required bool expanded,
  }) {
    final gain = device.bandGainAt(bandIndex);
    final gainParamId = 'band${bandIndex}Gain';

    return SizedBox(
      width: MbSplitLayout.bandCol,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SplitBranchToggleButton(
            label: label,
            active: expanded,
            accentColor: accent,
            centerBody: true,
            onPressed: () => onToggleBand(bandIndex),
          ),
          const SizedBox(height: 4),
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
            accentColor: accent,
            size: DeviceKnobSizes.compact,
          ),
        ],
      ),
    );
  }
}
