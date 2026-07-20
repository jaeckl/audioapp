part of 'library_preset_preview_bar.dart';

/// One clip on the preset scrub minimap.
class PresetPreviewClipSpan {
  const PresetPreviewClipSpan({
    required this.name,
    required this.kind,
    required this.startBeat,
    required this.lengthBeats,
    this.notes = const [],
    this.loopContent = false,
    this.contentLengthBeats = 0,
  });

  final String name;
  final ClipContentKind kind;
  final double startBeat;
  final double lengthBeats;
  final List<MidiNoteSnapshot> notes;
  final bool loopContent;
  final double contentLengthBeats;
}
