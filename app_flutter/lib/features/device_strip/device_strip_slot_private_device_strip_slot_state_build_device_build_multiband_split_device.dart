part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildmultibandsplitdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildMultibandSplitDevice(BuildContext context, double contentHeight) {
    final device = widget.device as MultibandSplitDeviceSnapshot;
    return MultibandSplitPanel(
      device: device,
      onChanged: widget.onDeviceParameterChanged,
      onToggleBand: widget.onToggleMultibandBand ?? (_) {},
      expandedBands: widget.multibandExpandedBands,
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
