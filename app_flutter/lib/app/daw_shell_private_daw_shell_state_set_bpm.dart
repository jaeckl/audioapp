part of 'daw_shell.dart';

extension DawShellStateSetbpmOperation on _DawShellState {
Future<void> _setBpm(int bpm) async {
    try {
      await _applyDeltaMutation('setBpm', {'bpm': bpm});
      if (_transport.playing) {
        await _transport.syncTransportState();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
