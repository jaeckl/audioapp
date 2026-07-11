part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuilddevicechaindeviceOperation
    on _DeviceStripSlotState {
  Widget _buildDeviceChainDevice(BuildContext context, double contentHeight) {
    return ChainDevicePanel(
      device: widget.device as ChainDeviceSnapshot,
      onChanged: widget.onDeviceParameterChanged,
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
    );
  }
}
