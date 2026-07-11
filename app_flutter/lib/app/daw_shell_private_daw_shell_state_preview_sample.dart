part of 'daw_shell.dart';

extension DawShellStatePreviewsampleOperation on _DawShellState {
Future<void> _previewSample(SampleLibraryEntrySnapshot sample) async {
    try {
      await widget.bridge.previewSample(sample.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
