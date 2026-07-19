part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildspectralloudsplitdeviceOperation
    on _DeviceStripSlotState {
  Widget _buildSpectralLoudSplitDevice(
      BuildContext context, double contentHeight) {
    final device = widget.device as SpectralLoudSplitDeviceSnapshot;
    final listenable = widget.liveMetersListenable;

    Widget panel(DeviceMeterReading? liveMeter) {
      final wave = liveMeter?.waveform ?? const <double>[];
      final levels = [
        wave.isNotEmpty ? wave[0] : 0.0,
        wave.length > 1 ? wave[1] : 0.0,
        wave.length > 2 ? wave[2] : 0.0,
      ];
      return SpectralLoudSplitPanel(
        device: device,
        onChanged: widget.onDeviceParameterChanged,
        onToggleBand: widget.onToggleSpectralLoudBand ?? (_) {},
        expandedBands: widget.spectralLoudExpandedBands,
        spectrum: liveMeter?.spectrum ?? const [],
        bandLevels: levels,
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

    if (listenable == null) return panel(null);
    return ValueListenableBuilder<Map<String, DeviceMeterReading>>(
      valueListenable: listenable,
      builder: (context, meters, _) => panel(meters[widget.device.id]),
    );
  }
}
