part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildresonatorbankdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildResonatorBankDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as ResonatorBankDeviceSnapshot;
    // Full-bleed modal hero — skip DeviceStripViewport letterbox.
    return SizedBox(
      width: _cardWidth,
      height: contentHeight,
      child: ResonatorBankPanel(
        device: dev,
        onParameterChanged: widget.onDeviceParameterChanged,
        modulatedParams: _modulatedParamIds,
        automatedParams: _automatedParamIds,
        modulationAmounts: _modulationAmounts,
        connectModeLfoId: _connectModeLfo,
        onModulationAssign: _onModulationForDevice,
        automationLinkActive: widget.automationLinkActive,
        onAutomationLinkTap: widget.onAutomationParamSelected != null
            ? _onAutomationLinkTap
            : null,
        onAutomateParameter:
            widget.onAutomateParameter != null ? _onAutomateParameter : null,
      ),
    );
  }
}
