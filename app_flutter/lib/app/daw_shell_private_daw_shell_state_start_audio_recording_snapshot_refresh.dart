part of 'daw_shell.dart';

extension DawShellStateStartaudiorecordingsnapshotrefreshOperation on _DawShellState {
void _startAudioRecordingSnapshotRefresh() {
    _audioRecordingSnapshotTimer?.cancel();
    _audioRecordingSnapshotTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) async {
        if (!_anyRecordingActive) return;
        try {
          final transport = await widget.bridge.getTransportState();
          await _rollLoopRecordingIfNeeded(transport);
          await _updateLiveRecordingPreviews(transport);
          await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
          if (_audioRecordingActive) {
            final level = await widget.bridge.getTrackAudioRecordingLevel();
            if (mounted) {
              setState(() => _audioRecordingInputLevel = level);
            }
          }
        } catch (_) {}
      },
    );
  }
}
