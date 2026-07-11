part of 'daw_shell.dart';

extension DawShellStateResizeclipOperation on _DawShellState {
Future<void> _resizeClip({
    required String clipId,
    required double lengthBeats,
  }) async {
    try {
      final snapshot = await widget.bridge.setClipLength(
        clipId: clipId,
        lengthBeats: lengthBeats,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
