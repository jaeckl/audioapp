part of 'device_strip_slot.dart';

extension DeviceStripSlotStateSeqknobsOperation on _DeviceStripSlotState {
  Widget _seqKnobs(
      LfoSnapshot mod, Future<void> Function(String, double) onUpdate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Center(
            child: RotaryKnob(
              label: 'Rate',
              value: mod.rate.clamp(0.0, 1.0),
              displayValue: ModulatorRateCodec.formatRate(mod),
              size: DeviceKnobSizes.compact,
              accentColor: _seqAccent,
              onChanged: (v) => onUpdate('rate', v),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: RotaryKnob(
              label: 'Smooth',
              value: mod.smoothing.clamp(0.0, 1.0),
              displayValue: '${(mod.smoothing * 100).round()}%',
              size: DeviceKnobSizes.compact,
              accentColor: _seqAccent,
              onChanged: (v) => onUpdate('smoothing', v),
            ),
          ),
        ),
      ],
    );
  }
}
