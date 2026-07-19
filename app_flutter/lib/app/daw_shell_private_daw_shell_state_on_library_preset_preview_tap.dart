part of 'daw_shell.dart';

extension DawShellStateOnlibrarypresetpreviewtapOperation on _DawShellState {
  Future<void> _onLibraryPresetPreviewTap(LibraryPresetItem item,
      {double startBeat = 0.0, bool loop = true}) async {
    final previewType =
        FactoryPresetJson.previewDeviceType(item.id) ?? item.deviceType;
    final params = FactoryPresetJson.flatParamsForPreview(item.id) ??
        DevicePresetStore.find(item.deviceType, item.id)?.params;
    debugPrint(
        '[library preset] item.id=${item.id} deviceType=${item.deviceType} '
        'previewType=$previewType startBeat=$startBeat loop=$loop '
        'presetFound=${params != null}');
    if (params == null) {
      return;
    }

    final track = _snapshot?.selectedTrack;
    final notes = <MidiNoteSnapshot>[];
    double maxBeat = 8.0;

    if (track != null) {
      for (final clip in track.midiClips) {
        final clipEnd = clip.startBeat + clip.lengthBeats;
        if (clipEnd > maxBeat) {
          maxBeat = clipEnd;
        }
        for (final note in clip.notes) {
          notes.add(MidiNoteSnapshot(
            pitch: note.pitch,
            startBeat: clip.startBeat + note.startBeat,
            durationBeats: note.durationBeats,
            velocity: note.velocity,
          ));
        }
      }
    }

    if (notes.isEmpty) {
      notes.add(const MidiNoteSnapshot(
          pitch: 48, startBeat: 0.0, durationBeats: 1.0, velocity: 90.0));
      notes.add(const MidiNoteSnapshot(
          pitch: 52, startBeat: 1.0, durationBeats: 1.0, velocity: 90.0));
      notes.add(const MidiNoteSnapshot(
          pitch: 55, startBeat: 2.0, durationBeats: 1.0, velocity: 90.0));
      notes.add(const MidiNoteSnapshot(
          pitch: 60, startBeat: 3.0, durationBeats: 1.0, velocity: 90.0));
      maxBeat = 4.0;
    }

    final bpm = _snapshot?.bpm ?? 120;
    try {
      await widget.bridge.previewPreset(
        deviceType: previewType,
        params: params,
        notes: notes,
        lengthBeats: maxBeat,
        bpm: bpm,
        startBeat: startBeat,
        loop: loop,
      );
    } catch (e) {
      debugPrint('[library preset] previewPreset FAILED for ${item.id}: $e');
    }
  }
}
