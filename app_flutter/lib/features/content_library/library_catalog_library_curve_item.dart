part of 'library_catalog.dart';

class LibraryCurveItem extends LibraryItem {
  const LibraryCurveItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.resource,
    super.tags,
  });

  final CurveLibraryResource resource;
}
