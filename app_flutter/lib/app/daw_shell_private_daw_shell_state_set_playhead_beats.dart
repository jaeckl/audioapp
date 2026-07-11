part of 'daw_shell.dart';

extension DawShellStateSetplayheadbeatsOperation on _DawShellState {
Future<void> _setPlayheadBeats(double beats) async {
    try {
      await _transport.setPlayheadBeats(beats);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
