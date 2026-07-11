part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildaudioreceiverdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildAudioReceiverDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as RoutingDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: RoutingDevicePanel(
        device: dev,
        onParameterChanged: widget.onDeviceParameterChanged,
        sources: widget.routingSources
            .where((source) => source.isMidi == !dev.isAudioRoute)
            .toList(),
        onSourceChanged: (value) =>
            widget.onDeviceStringParameterChanged?.call('sourceId', value),
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
