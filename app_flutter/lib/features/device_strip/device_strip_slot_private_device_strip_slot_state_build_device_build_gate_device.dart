part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildgatedeviceOperation
    on _DeviceStripSlotState {
  Widget _buildGateDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as GateDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: GateDeviceStrip(
        device: dev,
        onParameterChanged: widget.onDeviceParameterChanged,
        selectedTab: GateDeviceTab.values[_selectedTabIndex.clamp(0, 2)],
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
