part of 'library_catalog.dart';

class LibraryAudioItem extends LibraryItem {
  const LibraryAudioItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.sample,
    this.isProjectClip = false,
    super.tags,
  });

  final SampleLibraryEntrySnapshot sample;
  final bool isProjectClip;
}
