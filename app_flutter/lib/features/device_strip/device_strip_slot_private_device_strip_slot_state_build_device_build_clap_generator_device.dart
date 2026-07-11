part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildclapgeneratordeviceOperation
    on _DeviceStripSlotState {
  Widget _buildClapGeneratorDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as ClapGeneratorDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: ClapGeneratorDeviceStrip(
        device: dev,
        onParameterChanged: widget.onDeviceParameterChanged,
        selectedTab: ClapDeviceTab.values[_selectedTabIndex.clamp(0, 2)],
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
