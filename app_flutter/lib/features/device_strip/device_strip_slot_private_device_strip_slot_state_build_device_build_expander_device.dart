part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildexpanderdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildExpanderDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as ExpanderDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: ExpanderDeviceStrip(
        device: dev,
        onParameterChanged: widget.onDeviceParameterChanged,
        selectedTab: ExpanderDeviceTab.values[_selectedTabIndex.clamp(0, 2)],
        modulatedParams: _modulatedParamIds,
        automatedParams: _automatedParamIds,
        modulationAmounts: _modulationAmounts,
        lfos: _localLfos,
        modEdges: _localModEdges,
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
