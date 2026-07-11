part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildwavetablesynthdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildWavetableSynthDevice(
      BuildContext context, double contentHeight) {
    final dev = widget.device as WavetableSynthDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: WavetableSynthDeviceStrip(
        device: dev,
        onParameterChanged: widget.onSamplerParameterChanged,
        selectedTab: WavetableSynthDeviceTab.values[_selectedTabIndex],
        onTabChanged: widget.onWtTabChanged,
        onOpenFullscreen: widget.onOpenSamplerEditor,
        onOpenWavetableLibrary: widget.onOpenLibrary != null
            ? () => widget
                .onOpenLibrary!(libraryFilterForDeviceType(widget.device.type))
            : null,
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
