part of 'piano_roll_screen.dart';

extension _PianoRollScreenStatePersistscalesettings on _PianoRollScreenState {
  Future<void> _persistScaleSettings(PianoRollScaleSettings settings) async {
    try {
      await widget.bridge.setMidiClipEditorScale(
        clipId: widget.clip.id,
        rootPitchClass: settings.rootPitchClass,
        scaleId: settings.scale.id,
        highlight: settings.highlight,
        snapToScale: settings.snapToScale,
        chordQuality: settings.chordQuality.name,
      );
    } catch (_) {
      // Editor metadata is non-audio-critical; keep local state if bridge save fails.
    }
  }
}
