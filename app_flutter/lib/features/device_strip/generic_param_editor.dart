/// A generic parameter editor widget that renders controls from metadata.
/// Falls back when no custom device editor exists.
library;
import 'package:flutter/material.dart';

import '../../bridge/param_descriptor.dart';
import 'device_knob_sizes.dart';
import 'device_strip_theme.dart';
import 'rotary_knob.dart';

/// Renders a wrap of knobs for each parameter in [params].
/// Used as a fallback for unknown device types.
class GenericParamEditor extends StatelessWidget {
  const GenericParamEditor({
    super.key,
    required this.params,
    required this.currentValues,
    required this.modulationAmounts,
    required this.onParameterChanged,
  });

  final List<DeviceParamDescriptor> params;
  final Map<String, double> currentValues;
  final Map<String, double> modulationAmounts;
  final void Function(String parameterId, double value) onParameterChanged;

  @override
  Widget build(BuildContext context) {
    if (params.isEmpty) {
      return const Center(
        child: Text(
          'No parameters',
          style: TextStyle(color: Colors.white24, fontSize: 10),
        ),
      );
    }

    const double knobSize = DeviceKnobSizes.compact;
    const double gap = 4;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        alignment: WrapAlignment.center,
        children: params.map((param) {
          final current = currentValues[param.stableName] ?? param.defaultValue;
          final modAmount =
              modulationAmounts[param.stableName] ?? 0.0;
          return SizedBox(
            width: knobSize,
            child: RotaryKnob(
              label: param.displayName,
              value: (current - param.min) / (param.max - param.min),
              onChanged: (normalized) {
                final actual =
                    param.min + normalized * (param.max - param.min);
                onParameterChanged(param.stableName, actual);
              },
              size: DeviceKnobSizes.compact,
              accentColor: DeviceStripTheme.genericAccent,
              modulationAmount: modAmount,
            ),
          );
        }).toList(),
      ),
    );
  }
}