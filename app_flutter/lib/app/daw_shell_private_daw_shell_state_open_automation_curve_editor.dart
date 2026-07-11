part of 'daw_shell.dart';

extension DawShellStateOpenautomationcurveeditorOperation on _DawShellState {
Future<void> _openAutomationCurveEditor(
    String trackId,
    AutomationClipSnapshot clip,
  ) async {
    final track = _trackById(trackId);
    if (track == null) return;

    // Always open with engine-backed points (arrangement [clip] may be stale).
    AutomationClipSnapshot editorClip = clip;
    try {
      final fresh = await widget.bridge.getProjectSnapshot();
      for (final candidate in fresh.automationClips) {
        if (candidate.id == clip.id) {
          editorClip = candidate;
          break;
        }
      }
    } catch (_) {
      // Fall back to the clip snapshot we already have.
    }

    if (!mounted) return;
    final savedPlayhead = await _beginClipEditorSession();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AutomationEditorScreen(
          trackName: track.name,
          clip: editorClip,
          bridge: widget.bridge,
          onSaved: _refreshSnapshot,
          savedArrangementPlayhead: savedPlayhead,
          bpm: _snapshot?.bpm ?? 120,
        ),
      ),
    );
    await _endClipEditorSession();
  }
}
