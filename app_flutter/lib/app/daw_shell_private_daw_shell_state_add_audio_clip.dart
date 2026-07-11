part of 'daw_shell.dart';

extension DawShellStateAddaudioclipOperation on _DawShellState {
Future<void> _addAudioClip(String trackId, double desiredStartBeat) async {
    await _selectTrack(trackId);
    if (!mounted) return;

    final sample = await showModalBottomSheet<SampleLibraryEntrySnapshot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0E14),
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: SampleLibraryPickerSheet(
          initialSamples: _snapshot?.samples ?? const [],
          onPreview: _previewSample,
          onImportSamples: () async {
            final updated = await widget.bridge.importSample();
            if (updated != null) {
              await _refreshSnapshot(updated);
              return updated.samples;
            }
            return _snapshot?.samples ?? const [];
          },
          onSampleSelected: (entry) => Navigator.pop(context, entry),
        ),
      ),
    );
    if (sample == null) return;

    final track = _trackById(trackId);
    if (track == null) return;
    if (track.freeze.enabled) {
      _showFrozenTrackSnack();
      return;
    }

    final startBeat = ArrangementTimelineMetrics.placementStartBeat(
      desiredStartBeat: desiredStartBeat,
      clipLengthBeats: sample.durationBeats,
      existingClips: ArrangementTimelineMetrics.clipIntervalsForTrack(track),
    );

    try {
      final updated = await widget.bridge.createSampleClip(
        trackId: trackId,
        sampleId: sample.id,
        startBeat: startBeat,
        lengthBeats: sample.durationBeats,
      );
      await _refreshSnapshot(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
