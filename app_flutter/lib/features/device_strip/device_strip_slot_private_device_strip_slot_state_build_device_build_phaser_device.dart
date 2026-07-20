part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildphaserdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildPhaserDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as PhaserDeviceSnapshot;
    // Full-bleed center hero — skip DeviceStripViewport letterbox.
    return SizedBox(
      width: _cardWidth,
      height: contentHeight,
      child: PhaserFxStrip(
        device: dev,
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
