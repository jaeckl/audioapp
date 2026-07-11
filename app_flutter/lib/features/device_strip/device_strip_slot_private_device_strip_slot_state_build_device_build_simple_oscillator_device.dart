part of 'device_strip_slot.dart';

extension DeviceStripSlotStateBuildsimpleoscillatordeviceOperation
    on _DeviceStripSlotState {
  Widget _buildSimpleOscillatorDevice(
      BuildContext context, double contentHeight) {
    final dev = widget.device as OscillatorDeviceSnapshot;
    return DeviceStripViewport(
      shrinkWrap: true,
      designWidth: _cardWidth,
      designHeight: contentHeight,
      child: OscillatorDevicePanel(
        trackName: widget.track.name,
        frequencyHz: dev.frequencyHz,
        onFrequencyChanged: widget.onFrequencyChanged,
        onCollapse: widget.onCollapse,
        embeddedInCard: true,
        selectedTab: OscillatorDeviceTab.values[_selectedTabIndex],
        modulatedParams: _modulatedParamIds,
        automatedParams: _automatedParamIds,
        modulationAmounts: _modulationAmounts,
        connectModeLfoId: _connectModeLfo,
        onModulationAssign:
            _connectModeLfo != null ? _onModulationFor('frequency') : null,
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
