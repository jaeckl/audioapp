part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildsubtractivesynthdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildSubtractiveSynthDevice(
      BuildContext context, double contentHeight) {
    final dev = widget.device as SubtractiveSynthDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: SubtractiveSynthDeviceStrip(
        device: dev,
        onParameterChanged: widget.onSamplerParameterChanged,
        selectedTab: SubtractiveDeviceTab.values[_selectedTabIndex],
        onTabChanged: widget.onSynthTabChanged,
        onOpenFullscreen: widget.onOpenSamplerEditor,
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
