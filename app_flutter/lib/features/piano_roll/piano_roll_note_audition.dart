import 'dart:async';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';

/// Audition notes in the piano roll via live noteOn/noteOff (not clip playback).
class PianoRollNoteAudition {
  PianoRollNoteAudition({
    required this.bridge,
    required this.bpm,
    this.drumAnchorPitch,
  });

  final EngineBridge bridge;
  int bpm;
  final int? drumAnchorPitch;

  int? _heldPitch;
  Timer? _releaseTimer;

  int _previewPitch(MidiNoteSnapshot note) => drumAnchorPitch ?? note.pitch;

  Future<void> preview(MidiNoteSnapshot note, {bool hold = false}) async {
    await release();
    final pitch = _previewPitch(note);
    final velocity = note.velocity.toDouble().clamp(1.0, 127.0);
    await bridge.noteOn(pitch: pitch, velocity: velocity);
    _heldPitch = pitch;
    if (!hold) {
      final ms = (note.durationBeats * 60000.0 / bpm).round().clamp(100, 4000);
      _releaseTimer = Timer(Duration(milliseconds: ms), () {
        unawaited(release());
      });
    }
  }

  Future<void> release() async {
    _releaseTimer?.cancel();
    _releaseTimer = null;
    final pitch = _heldPitch;
    _heldPitch = null;
    if (pitch != null) {
      await bridge.noteOff(pitch: pitch);
    }
  }
}
