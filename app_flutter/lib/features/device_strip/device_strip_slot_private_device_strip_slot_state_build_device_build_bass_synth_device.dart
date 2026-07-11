part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildbasssynthdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildBassSynthDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as BassSynthDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: BassSynthDeviceStrip(
        device: dev,
        onParameterChanged: widget.onSamplerParameterChanged,
        selectedTab: BassSynthDeviceTab.values[_selectedTabIndex],
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
