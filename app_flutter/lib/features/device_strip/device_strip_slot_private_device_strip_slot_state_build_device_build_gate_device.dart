part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildgatedeviceOperation
    on _DeviceStripSlotState {
  Widget _buildGateDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as GateDeviceSnapshot;
    // Full-bleed transfer hero — skip DeviceStripViewport letterbox.
    return SizedBox(
      width: _cardWidth,
      height: contentHeight,
      child: GateDeviceStrip(
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
