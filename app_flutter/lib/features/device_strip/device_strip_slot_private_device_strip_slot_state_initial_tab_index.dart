part of 'device_strip_slot.dart';

extension DeviceStripSlotStateInitialtabindexOperation
    on _DeviceStripSlotState {
  int _initialTabIndex() {
    if (widget.device.type == 'simple_sampler') {
      return widget.samplerTab.index;
    }
    if (widget.device.type == 'subtractive_synth') {
      return widget.synthTab.index;
    }
    if (widget.device.type == 'bass_synth') {
      return widget.bassTab.index;
    }
    if (widget.device.type == 'phase_mod_synth') {
      return widget.pmTab.index;
    }
    if (widget.device.type == 'wavetable_synth') {
      return widget.wtTab.index;
    }
    return 0;
  }
}
