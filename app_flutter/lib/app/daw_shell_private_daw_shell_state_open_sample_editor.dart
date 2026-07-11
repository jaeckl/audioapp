part of 'daw_shell.dart';

extension DawShellStateOpensampleeditorOperation on _DawShellState {
Future<void> _openSampleEditor(
      String trackId, SampleClipSnapshot clip) async {
    TrackSnapshot? track;
    for (final candidate in _snapshot?.tracks ?? const <TrackSnapshot>[]) {
      if (candidate.id == trackId) {
        track = candidate;
        break;
      }
    }
    if (track == null) return;
    final savedPlayhead = await _beginClipEditorSession();
    if (!mounted) return;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => SampleEditorScreen(
        bridge: widget.bridge,
        clip: clip,
        trackName: track!.name,
        samples: _snapshot?.samples ?? const [],
        onSnapshot: _refreshSnapshot,
        bpm: _snapshot?.bpm ?? 120,
        savedArrangementPlayhead: savedPlayhead,
      ),
    ));
    await _endClipEditorSession();
    try {
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
    } catch (_) {}
  }
}
