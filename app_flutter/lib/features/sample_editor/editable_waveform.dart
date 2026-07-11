import 'dart:math' as math;
import 'package:flutter/material.dart';

part 'editable_waveform_wave_handle.dart';
part 'editable_waveform_editable_waveform_state.dart';
part 'editable_waveform_waveform_painter.dart';

class EditableWaveform extends StatefulWidget {
  const EditableWaveform(
      {super.key,
      required this.peaks,
      required this.start,
      required this.end,
      required this.fadeIn,
      required this.fadeOut,
      required this.fadeInCurve,
      required this.fadeOutCurve,
      required this.gain,
      required this.reversed,
      required this.trimToolActive,
      required this.fadeToolActive,
      required this.sliceToolActive,
      required this.sliceMarkers,
      required this.onSliceToggle,
      required this.selectedSlice,
      required this.onSliceMove,
      required this.onSliceMoveEnd,
      required this.onSliceAudition,
      required this.onTrimChanged,
      required this.onFadesChanged,
      required this.onCurvesChanged,
      required this.onInteractionChanged,
      required this.onEditEnd,
      this.playhead = 0});
  final List<double> peaks;
  final double start,
      end,
      fadeIn,
      fadeOut,
      fadeInCurve,
      fadeOutCurve,
      gain,
      playhead;
  final bool reversed;
  final bool trimToolActive, fadeToolActive;
  final bool sliceToolActive;
  final List<double> sliceMarkers;
  final ValueChanged<double> onSliceToggle;
  final int? selectedSlice;
  final void Function(int, double) onSliceMove;
  final VoidCallback onSliceMoveEnd;
  final ValueChanged<double> onSliceAudition;
  final void Function(double start, double end) onTrimChanged;
  final void Function(double fadeIn, double fadeOut) onFadesChanged;
  final void Function(double fadeInCurve, double fadeOutCurve) onCurvesChanged;
  final ValueChanged<bool> onInteractionChanged;
  final VoidCallback onEditEnd;
  @override
  State<EditableWaveform> createState() => _EditableWaveformState();
}
