part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateNormalizeOperation on _SampleEditorScreenState {
void _normalize() {
    final peak = widget.clip.waveformPeaks
        .fold<double>(0, (m, p) => p.abs() > m ? p.abs() : m);
    setState(() => gain = peak <= .0001 ? 1 : (1 / peak).clamp(0.0, 4.0));
    _save();
  }
}
