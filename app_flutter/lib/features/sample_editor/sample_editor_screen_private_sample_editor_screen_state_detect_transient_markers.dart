part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateDetecttransientmarkersOperation on _SampleEditorScreenState {
List<double> _detectTransientMarkers() {
    final peaks = widget.clip.waveformPeaks;
    if (peaks.length < 3) return const [];
    final average =
        peaks.fold<double>(0, (sum, value) => sum + value.abs()) / peaks.length;
    final threshold = average * (1.05 + transientSensitivity * 1.8);
    final found = <double>[];
    var lastForward = -1.0;
    final window = math.max(.001, end - start);
    for (var i = 1; i < peaks.length - 1 && found.length < 16; i++) {
      final value = peaks[i].abs();
      final sourcePosition = i / (peaks.length - 1);
      if (sourcePosition < start || sourcePosition > end) continue;
      final forward = (sourcePosition - start) / window;
      final position = reversed ? 1 - forward : forward;
      if (value > threshold &&
          value >= peaks[i - 1].abs() &&
          value > peaks[i + 1].abs() &&
          forward - lastForward > sliceMinGap) {
        found.add(position);
        lastForward = forward;
      }
    }
    return found;
  }
}
