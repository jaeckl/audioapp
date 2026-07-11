part of 'library_catalog.dart';

class LibraryMidiItem extends LibraryItem {
  const LibraryMidiItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.clip,
    this.trackId,
    this.isFactory = false,
    super.tags,
  });

  final String? trackId;
  final MidiClipSnapshot clip;
  final bool isFactory;
}
