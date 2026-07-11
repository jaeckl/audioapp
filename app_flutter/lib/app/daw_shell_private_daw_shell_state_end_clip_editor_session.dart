part of 'daw_shell.dart';

extension DawShellStateEndclipeditorsessionOperation on _DawShellState {
Future<void> _endClipEditorSession() async {
    if (mounted) {
      setState(() => _frozenArrangementPlayhead = null);
    }
    await _transport.syncTransportState();
  }
}
