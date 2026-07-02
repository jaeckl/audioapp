import 'package:flutter/material.dart';
import '../../bridge/project_snapshot.dart';
import 'device_automation_knob.dart';
import 'device_knob_sizes.dart';

class ChainDevicePanel extends StatelessWidget {
  const ChainDevicePanel(
      {super.key, required this.device, required this.onChanged});
  static const double designWidth = 152;
  static const accent = Color(0xFF62C7B5);
  final ChainDeviceSnapshot device;
  final void Function(String, double) onChanged;

  @override
  Widget build(BuildContext context) => Center(
          child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          deviceAutomationKnob(
              label: 'Mix',
              value: device.mix,
              displayValue: '${(device.mix * 100).round()}%',
              onChanged: (v) => onChanged('chainMix', v),
              paramId: 'chainMix',
              deviceId: device.id,
              accentColor: accent,
              size: DeviceKnobSizes.strip + 4),
          deviceAutomationKnob(
              label: 'Gain',
              value: device.chainGain / 2,
              displayValue: '${(device.chainGain * 100).round()}%',
              onChanged: (v) => onChanged('chainGain', v * 2),
              paramId: 'chainGain',
              deviceId: device.id,
              accentColor: accent,
              size: DeviceKnobSizes.strip + 4),
        ],
      ));
}
