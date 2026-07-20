part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildlimiterdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildLimiterDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as LimiterDeviceSnapshot;
    // Full-bleed transfer hero — skip DeviceStripViewport letterbox.
    return SizedBox(
      width: _cardWidth,
      height: contentHeight,
      child: LimiterDeviceStrip(
        device: dev,
        onParameterChanged: widget.onDeviceParameterChanged,
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
