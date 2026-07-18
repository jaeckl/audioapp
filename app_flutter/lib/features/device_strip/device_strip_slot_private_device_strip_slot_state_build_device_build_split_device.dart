part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildsplitdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildSplitDevice(BuildContext context, double contentHeight) {
    final device = widget.device as SplitDeviceSnapshot;
    final listenable = widget.liveMetersListenable;
    Widget panel(DeviceMeterReading? liveMeter) => SplitDevicePanel(
          device: device,
          onChanged: widget.onDeviceParameterChanged,
          onToggleBranch:
              widget.onToggleSplitBranch ?? (branchIndex) {},
          branch0Expanded: widget.splitBranch0Expanded,
          branch1Expanded: widget.splitBranch1Expanded,
          liveMeter: liveMeter,
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

    if (listenable == null) return panel(null);
    return ValueListenableBuilder<Map<String, DeviceMeterReading>>(
      valueListenable: listenable,
      builder: (context, meters, _) => panel(meters[widget.device.id]),
    );
  }
}
