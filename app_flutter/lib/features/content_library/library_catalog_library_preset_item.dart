part of 'library_catalog.dart';

class LibraryPresetItem extends LibraryItem {
  const LibraryPresetItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required this.deviceType,
    this.isUser = false,
    this.presetJson,
    super.tags,
  });

  final String deviceType;
  final bool isUser;
  final String? presetJson;
}
