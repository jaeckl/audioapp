import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'rotary_knob.dart';

/// Shared gain + pan controls appended after every expanded device card.
class DeviceLevelPanel extends StatelessWidget {
  const DeviceLevelPanel({
    super.key,
    required this.device,
    required this.accentColor,
    required this.onParameterChanged,
    this.knobSize = DeviceKnobSizes.compact,
  });

  final DeviceSnapshot device;
  final Color accentColor;
  final void Function(String parameterId, double value) onParameterChanged;
  final double knobSize;

  static String formatGain(double gain) => '${(gain.clamp(0, 1) * 100).round()}%';

  static String formatPan(double pan) {
    final value = pan.clamp(0, 1);
    if ((value - 0.5).abs() < 0.02) return 'C';
    if (value < 0.5) {
      return 'L${((0.5 - value) * 200).round()}';
    }
    return 'R${((value - 0.5) * 200).round()}';
  }

  @override
  Widget build(BuildContext context) {
    const borderSide = BorderSide(
      color: DeviceStripTheme.cardBorder,
      width: DeviceStripTheme.cardBorderWidth,
    );
    final rightRadius = Radius.circular(DeviceStripTheme.toolRailRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DeviceStripTheme.toolRailBackground,
        borderRadius: BorderRadius.only(topRight: rightRadius, bottomRight: rightRadius),
        border: const Border(
          top: borderSide,
          bottom: borderSide,
          right: borderSide,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotaryKnob(
              label: 'Pan',
              value: device.pan.clamp(0, 1),
              size: knobSize,
              accentColor: accentColor,
              displayValue: formatPan(device.pan),
              onChanged: (value) => onParameterChanged('pan', value),
            ),
            const SizedBox(height: 8),
            RotaryKnob(
              label: 'Gain',
              value: device.gain.clamp(0, 1),
              size: knobSize,
              accentColor: accentColor,
              displayValue: formatGain(device.gain),
              onChanged: (value) => onParameterChanged('gain', value),
            ),
          ],
        ),
      ),
    );
  }
}
