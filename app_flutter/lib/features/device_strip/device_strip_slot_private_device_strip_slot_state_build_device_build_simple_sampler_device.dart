part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildsimplesamplerdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildSimpleSamplerDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as SamplerDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: SamplerDeviceStrip(
        device: dev,
        sample: widget.sample,
        bpm: widget.bpm,
        onParameterChanged: widget.onSamplerParameterChanged,
        onTabChanged: widget.onSamplerTabChanged,
        onCollapse: widget.onCollapse,
        onPreview: widget.sample != null && widget.onPreviewSampler != null
            ? () => widget.onPreviewSampler!(dev.rootPitch.round())
            : null,
        onLoadSample: widget.onOpenLibrary != null
            ? () => widget
                .onOpenLibrary!(libraryFilterForDeviceType(widget.device.type))
            : null,
        selectedTab: SamplerDeviceTab.values[_selectedTabIndex],
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
