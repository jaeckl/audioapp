part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildfrequencyshifterdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildFrequencyShifterDevice(
      BuildContext context, double contentHeight) {
    final dev = widget.device as FrequencyShifterDeviceSnapshot;
    // Full-bleed sideband hero — skip DeviceStripViewport letterbox.
    return SizedBox(
      width: _cardWidth,
      height: contentHeight,
      child: FreqShifterDeviceStrip(
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
