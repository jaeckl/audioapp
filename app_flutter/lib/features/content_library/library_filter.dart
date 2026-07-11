import 'library_category.dart';
import '../../devices/device_repository.dart';

/// Describes what the content library should show when opened for a device.
///
/// Device definitions own the category and tag preferences used here.
class LibraryFilter {
  final String deviceType;
  final LibraryCategory defaultCategory;
  final List<String> tags;
  final String? resourceType;

  const LibraryFilter({
    required this.deviceType,
    required this.defaultCategory,
    this.tags = const [],
    this.resourceType,
  });
}

LibraryFilter libraryFilterForDeviceType(String deviceType) {
  final picker = deviceDefinitionRepository.find(deviceType)?.picker;
  final categoryName = picker?.libraryCategory;
  final category = LibraryCategory.values
      .where((value) => value.name == categoryName)
      .firstOrNull;
  return LibraryFilter(
    deviceType: deviceType,
    defaultCategory: category ?? LibraryCategory.devicePresets,
    tags: picker?.libraryTags ?? const [],
  );
}
