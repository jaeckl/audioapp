part of 'daw_shell.dart';

extension DawShellStateSetcliploopcontentOperation on _DawShellState {
Future<void> _setClipLoopContent({
    required String clipId,
    required bool loopContent,
  }) async {
    try {
      final snapshot = await widget.bridge.setClipLoopContent(
        clipId: clipId,
        loopContent: loopContent,
      );
      await _refreshSnapshot(snapshot);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
