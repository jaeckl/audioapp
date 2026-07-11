import 'package:flutter/material.dart';

part 'draggable_int_value_box_draggable_int_value_box_state.dart';
part 'draggable_int_value_box_step_button.dart';

/// Compact integer readout — drag vertically to change value.
class DraggableIntValueBox extends StatefulWidget {
  const DraggableIntValueBox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
    this.min = -2,
    this.max = 2,
    this.label = 'Oct',
    this.showLabel = true,
    this.controlSize = 56,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final Color accentColor;
  final int min;
  final int max;
  final String label;
  final bool showLabel;
  final double controlSize;

  @override
  State<DraggableIntValueBox> createState() => _DraggableIntValueBoxState();
}

int subtractiveOctaveFromNorm(double norm) =>
    ((norm - 0.5) * 4).round().clamp(-2, 2);

double subtractiveNormFromOctave(int octave) => (octave / 4.0) + 0.5;
