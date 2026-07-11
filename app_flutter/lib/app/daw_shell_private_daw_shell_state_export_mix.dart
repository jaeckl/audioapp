part of 'daw_shell.dart';

extension DawShellStateExportmixOperation on _DawShellState {
Future<void> _exportMix() async {
    try {
      setState(() => _saveStatus = 'Rendering…');
      final length = _snapshot?.loopRegionEndBeat ?? 16.0;
      final uri = await widget.bridge.exportMix(lengthBeats: length);
      if (!mounted) return;
      setState(() => _saveStatus = uri == null ? null : 'Exported mix');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _projectError = e.toString();
        _saveStatus = null;
      });
    }
  }
}
