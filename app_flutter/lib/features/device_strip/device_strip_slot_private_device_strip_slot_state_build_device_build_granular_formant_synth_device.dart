part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildgranularformantsynthdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildGranularFormantSynthDevice(
      BuildContext context, double contentHeight) {
    return GranularDevicePanel(
      device: widget.device as GranularDeviceSnapshot,
      sample: widget.sample,
      tab: _selectedTabIndex.clamp(0, 2),
      playing: widget.playing,
      playheadBeat: widget.playheadBeat,
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
