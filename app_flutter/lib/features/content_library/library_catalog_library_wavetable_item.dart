part of 'library_catalog.dart';

class LibraryWavetableItem extends LibraryItem {
  const LibraryWavetableItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.wavetableName,
    super.tags,
  });

  final String wavetableName;
}
