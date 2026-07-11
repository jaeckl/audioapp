part of 'phase_mod_synth_device_panel.dart';

extension _PhaseModSynthDevicePanelStateDraggableratiobox
    on _PhaseModSynthDevicePanelState {
  Widget _draggableRatioBox({
    required int opIndex,
    required double value,
    required String paramId,
    required ValueChanged<double> onChanged,
  }) {
    // Uses the shared ValueDragBox widget — see value_drag_box.dart.
    return ValueDragBox(
      valueNorm: value,
      values: PhaseModSynthDevicePanel._ratioValues,
      format: (n) => PhaseModSynthDevicePanel.ratioDisplay(n),
      accent: PhaseModSynthDevicePanel.accent,
      paramId: paramId,
      modulatedParams: widget.modulatedParams,
      automatedParams: widget.automatedParams,
      modulationAmounts: widget.modulationAmounts,
      connectModeLfoId: widget.connectModeLfoId,
      onModulationAssign: widget.onModulationAssign,
      automationLinkActive: widget.automationLinkActive,
      onAutomationLinkTap: widget.onAutomationLinkTap,
      onAutomateParameter: widget.onAutomateParameter,
      onChanged: onChanged,
      resetIndex: 1, // 1.0 ratio
      dragPixelsPerStep: 12,
      footerLabel: 'Ratio',
    );
  }
}
