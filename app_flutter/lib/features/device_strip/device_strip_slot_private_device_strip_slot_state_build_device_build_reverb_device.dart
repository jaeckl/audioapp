part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildreverbdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildReverbDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as ReverbDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: ReverbFxStrip(
        device: dev,
        onParameterChanged: widget.onDeviceParameterChanged,
        selectedTab: ReverbViewTab.values[_selectedTabIndex.clamp(0, 2)],
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
