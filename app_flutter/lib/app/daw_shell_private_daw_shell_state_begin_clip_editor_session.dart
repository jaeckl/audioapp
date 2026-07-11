part of 'daw_shell.dart';

extension DawShellStateBeginclipeditorsessionOperation on _DawShellState {
Future<double> _beginClipEditorSession() async {
    if (_transport.playing) {
      await _transport.stopPlay();
    }
    final saved = _effectivePlayheadBeats;
    if (mounted) {
      setState(() => _frozenArrangementPlayhead = saved);
    }
    return saved;
  }
}
