part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildphasemodsynthdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildPhaseModSynthDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as PhaseModSynthDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: PhaseModSynthDeviceStrip(
        device: dev,
        onParameterChanged: widget.onSamplerParameterChanged,
        selectedTab: PhaseModSynthDeviceTab.values[_selectedTabIndex],
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
