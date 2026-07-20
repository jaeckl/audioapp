part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildduckerdeviceOperation on _DeviceStripSlotState {
  Widget _buildDuckerDevice(BuildContext context, double contentHeight) {
    final dev = widget.device as DuckerDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: DuckerDevicePanel(
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
        audioFxExpanded: widget.audioFxExpanded,
        onToggleAudioFx: widget.onToggleAudioFx,
      ),
    );
  }
}
