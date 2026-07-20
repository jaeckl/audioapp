part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildstutterfxdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildStutterFxDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as StutterDeviceSnapshot;
    // Full-bleed hero — skip DeviceStripViewport letterbox (same as Filter).
    return SizedBox(
      width: _cardWidth,
      height: contentHeight,
      child: StutterFxStrip(
        device: dev,
        selectedTab: StutterViewTab.values[_selectedTabIndex.clamp(0, 1)],
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
