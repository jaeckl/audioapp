part of 'device_strip_slot.dart';

extension DeviceStripSlotStateOntabselectedOperation on _DeviceStripSlotState {
  void _onTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
    if (widget.device.type == 'simple_sampler') {
      widget.onSamplerTabChanged?.call(SamplerDeviceTab.values[index]);
    }
    if (widget.device.type == 'subtractive_synth') {
      widget.onSynthTabChanged?.call(SubtractiveDeviceTab.values[index]);
    }
    if (widget.device.type == 'bass_synth') {
      widget.onBassTabChanged?.call(BassSynthDeviceTab.values[index]);
    }
    if (widget.device.type == 'phase_mod_synth') {
      widget.onPmTabChanged?.call(PhaseModSynthDeviceTab.values[index]);
    }
    if (widget.device.type == 'wavetable_synth') {
      widget.onWtTabChanged?.call(WavetableSynthDeviceTab.values[index]);
    }
  }
}
