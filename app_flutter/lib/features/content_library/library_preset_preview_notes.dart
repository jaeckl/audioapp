import 'dart:math' as math;

import '../../bridge/project_snapshot.dart';

/// Arrangement MIDI for device-preset audition (absolute beats).
///
/// Emits notes from **every** MIDI clip on the track. Looped clip content is
/// tiled across the clip span so preview matches arrangement playback.
/// Empty when the selected track has no notes — callers then use
/// [libraryPresetDemoArpeggio].
List<MidiNoteSnapshot> libraryPresetPreviewNotesFromClips(
  Iterable<MidiClipSnapshot> clips,
) {
  final out = <MidiNoteSnapshot>[];
  for (final clip in clips) {
    final contentLen = clip.loopContentLengthBeats;
    final looping = clip.loopContent &&
        contentLen > 0 &&
        clip.lengthBeats > contentLen + 1e-9;

    void addNote(double localStart, MidiNoteSnapshot note) {
      if (localStart >= clip.lengthBeats) return;
      final dur = math.min(
        note.durationBeats,
        clip.lengthBeats - localStart,
      );
      if (dur <= 0) return;
      out.add(MidiNoteSnapshot(
        pitch: note.pitch,
        startBeat: clip.startBeat + localStart,
        durationBeats: dur,
        velocity: note.velocity,
      ));
    }

    if (looping) {
      for (var origin = 0.0; origin < clip.lengthBeats; origin += contentLen) {
        for (final note in clip.notes) {
          addNote(origin + note.startBeat, note);
        }
      }
    } else {
      for (final note in clip.notes) {
        addNote(note.startBeat, note);
      }
    }
  }
  return out;
}

/// Demo phrase only when the selected track has no MIDI.
const libraryPresetDemoArpeggio = <MidiNoteSnapshot>[
  MidiNoteSnapshot(pitch: 48, startBeat: 0.0, durationBeats: 1.0, velocity: 90.0),
  MidiNoteSnapshot(pitch: 52, startBeat: 1.0, durationBeats: 1.0, velocity: 90.0),
  MidiNoteSnapshot(pitch: 55, startBeat: 2.0, durationBeats: 1.0, velocity: 90.0),
  MidiNoteSnapshot(pitch: 60, startBeat: 3.0, durationBeats: 1.0, velocity: 90.0),
];

/// Preset preview playhead range: arrangement loop end ∪ all track MIDI.
///
/// Always at least [loopRegionEndBeat] so preview covers the project loop /
/// arrangement window, and never shorter than the furthest MIDI on the track
/// so every clip stays audible.
double libraryPresetPreviewLengthBeats(
  Iterable<MidiClipSnapshot> clips, {
  required double loopRegionEndBeat,
  double emptyFallback = 4.0,
}) {
  var maxBeat = math.max(loopRegionEndBeat, emptyFallback);
  for (final clip in clips) {
    final clipEnd = clip.startBeat + clip.lengthBeats;
    if (clipEnd > maxBeat) maxBeat = clipEnd;
    for (final note in clip.notes) {
      final noteEnd = clip.startBeat + note.startBeat + note.durationBeats;
      if (noteEnd > maxBeat) maxBeat = noteEnd;
    }
  }
  return maxBeat;
}
