part of 'device_strip_slot.dart';

extension DeviceStripSlotStateChromebindingsOperation on _DeviceStripSlotState {
  DeviceStripChromeBindings _chromeBindings([DeviceMeterReading? liveMeter]) {
    final reading = liveMeter;
    return DeviceStripChromeBindings(
      device: widget.device,
      accentColor: DeviceStripTheme.accentForDeviceType(widget.device.type),
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
      gainReductionDb:
          reading?.gainReductionDb ?? widget.device.meterGainReductionDb,
      inputLevel: reading?.inputLevel ?? widget.device.meterInputLevel,
      audioFxExpanded: widget.audioFxExpanded,
      noteFxExpanded: widget.noteFxExpanded,
      onToggleAudioFx: widget.onToggleAudioFx,
      onToggleNoteFx: widget.onToggleNoteFx,
    );
  }
}
