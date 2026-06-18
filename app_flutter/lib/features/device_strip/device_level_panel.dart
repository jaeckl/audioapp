import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../../features/content_library/library_theme.dart';
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
    this.modulatedParams = const {},
    this.modulationAmounts = const {},
    this.connectModeLfoId,
    this.onModulationAssign,
    this.automationLinkActive = false,
    this.onAutomationLinkTap,
  });

  final DeviceSnapshot device;
  final Color accentColor;
  final void Function(String parameterId, double value) onParameterChanged;
  final double knobSize;
  final Set<String> modulatedParams;
  final Map<String, double> modulationAmounts;
  final int? connectModeLfoId;
  final void Function(String paramId, double amount)? onModulationAssign;
  final bool automationLinkActive;
  final ValueChanged<String>? onAutomationLinkTap;

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
              modulationActive: modulatedParams.contains('pan'),
              modulationAmount: modulationAmounts['pan'] ?? 0.0,
              connectModeActive: connectModeLfoId != null,
              onModulationAssign: onModulationAssign != null
                  ? (a) => onModulationAssign!('pan', a)
                  : null,
              linkModeActive: automationLinkActive,
              linkModeAccent: LibraryTheme.accentAutomation,
              onLinkTap: automationLinkActive && onAutomationLinkTap != null
                  ? () => onAutomationLinkTap!('pan')
                  : null,
            ),
            const SizedBox(height: 8),
            RotaryKnob(
              label: 'Gain',
              value: device.gain.clamp(0, 1),
              size: knobSize,
              accentColor: accentColor,
              displayValue: formatGain(device.gain),
              onChanged: (value) => onParameterChanged('gain', value),
              modulationActive: modulatedParams.contains('gain'),
              modulationAmount: modulationAmounts['gain'] ?? 0.0,
              connectModeActive: connectModeLfoId != null,
              onModulationAssign: onModulationAssign != null
                  ? (a) => onModulationAssign!('gain', a)
                  : null,
              linkModeActive: automationLinkActive,
              linkModeAccent: LibraryTheme.accentAutomation,
              onLinkTap: automationLinkActive && onAutomationLinkTap != null
                  ? () => onAutomationLinkTap!('gain')
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
