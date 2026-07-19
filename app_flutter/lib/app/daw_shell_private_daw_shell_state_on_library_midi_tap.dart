part of 'daw_shell.dart';

extension DawShellStateOnlibrarymiditapOperation on _DawShellState {
Future<void> _onLibraryMidiTap(LibraryMidiItem item) async {
    if (item.isFactory) {
      final track = _snapshot?.selectedTrack;
      if (track == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a track first')),
        );
        return;
      }
      if (track.freeze.enabled) {
        _showFrozenTrackSnack();
        return;
      }
      final startBeat = ArrangementTimelineMetrics.placementStartBeat(
        desiredStartBeat: _effectivePlayheadBeats,
        clipLengthBeats: item.clip.lengthBeats,
        existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
      );
      try {
        await widget.bridge.selectTrack(track.id);
        final beforeClipCount = track.midiClips.length;
        var snapshot = await widget.bridge.createMidiClip(
          trackId: track.id,
          startBeat: startBeat,
          lengthBeats: item.clip.lengthBeats,
        );
        final updatedTrack = snapshot.trackById(track.id);
        if (updatedTrack != null &&
            updatedTrack.midiClips.length > beforeClipCount) {
          final clip = updatedTrack.midiClips.last;
          snapshot = await widget.bridge.setMidiClipNotes(
            clipId: clip.id,
            notes: item.clip.notes,
          );
        }
        await _refreshSnapshot(snapshot);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inserted "${item.title}"')),
        );
        await _libraryPanelKey.currentState?.close();
      } catch (e) {
        if (!mounted) return;
        setState(() => _projectError = e.toString());
      }
      return;
    }
    if (item.trackId == null) {
      return;
    }
    await _openPianoRoll(item.trackId!, item.clip);
    await _libraryPanelKey.currentState?.close();
  }
}
