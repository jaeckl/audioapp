part of 'library_catalog.dart';

sealed class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> tags;
}
