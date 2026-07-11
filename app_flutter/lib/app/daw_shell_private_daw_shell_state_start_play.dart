part of 'daw_shell.dart';

extension DawShellStateStartplayOperation on _DawShellState {
Future<void> _startPlay() async {
    final beats = _effectivePlayheadBeats;
    final snap = _snapshot;
    final recordingDecision = decideRecordingSession(snap);
    try {
      await _transport.startPlay(
        beats,
        holdForCountIn: snap?.recordArmed == true && _countInBars > 0,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _projectError = e.toString());
      }
      return;
    }
    if (recordingDecision != null) {
      unawaited(_beginRecordingAfterCountIn(
        recordingDecision.trackId,
        beats,
        recordAudio: recordingDecision.recordAudio,
        recordMidi: recordingDecision.recordMidi,
        recordAutomation: recordingDecision.recordAutomation,
      ));
    }
    _arrangementScrollController.catchUpPlayheadOnPlay(beats);
    if (mounted) {
      setState(() {});
    }
  }
}
