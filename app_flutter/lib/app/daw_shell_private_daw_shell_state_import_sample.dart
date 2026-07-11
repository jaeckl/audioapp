part of 'daw_shell.dart';

extension DawShellStateImportsampleOperation on _DawShellState {
Future<void> _importSample() async {
    try {
      final updated = await widget.bridge.importSample();
      if (!mounted) return;
      if (updated != null) {
        await _refreshSnapshot(updated);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
