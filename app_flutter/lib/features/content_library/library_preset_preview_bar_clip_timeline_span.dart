part of 'library_preset_preview_bar.dart';

class ClipTimelineSpan {
  const ClipTimelineSpan({
    required this.name,
    required this.kind,
    required this.startBeat,
    required this.lengthBeats,
  });

  final String name;
  final ClipContentKind kind;
  final double startBeat;
  final double lengthBeats;
}
