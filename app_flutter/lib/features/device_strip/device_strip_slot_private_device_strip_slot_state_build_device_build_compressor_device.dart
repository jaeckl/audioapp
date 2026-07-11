part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildcompressordeviceOperation
    on _DeviceStripSlotState {
  Widget _buildCompressorDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as CompressorDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: CompressorDeviceStrip(
        device: dev,
        onParameterChanged: widget.onDeviceParameterChanged,
        selectedTab: CompressorDeviceTab.values[_selectedTabIndex.clamp(0, 2)],
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
