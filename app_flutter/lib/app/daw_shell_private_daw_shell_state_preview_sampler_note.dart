part of 'daw_shell.dart';

extension DawShellStatePreviewsamplernoteOperation on _DawShellState {
Future<void> _previewSamplerNote(int rootPitch) async {
    try {
      await widget.bridge.noteOn(pitch: rootPitch, velocity: 100);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await widget.bridge.noteOff(pitch: rootPitch);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
