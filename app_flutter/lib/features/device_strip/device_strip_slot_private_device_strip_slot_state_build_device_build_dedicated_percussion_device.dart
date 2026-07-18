part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildDedicatedPercussionDeviceOperation
    on _DeviceStripSlotState {
  Widget _buildDedicatedPercussionDevice(
      BuildContext context, double contentHeight) {
    final dev = widget.device as DedicatedPercussionDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: DedicatedPercussionDevicePanel(
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
