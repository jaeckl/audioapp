import '../../devices/device_repository.dart';
import '../../devices/definition/device_definition.dart';
import 'library_catalog.dart';
import 'library_device_family.dart';
import 'library_manifest.dart';
/// One row in the devices library — a bare device type or a preset.
sealed class LibraryDeviceBrowseItem {
  const LibraryDeviceBrowseItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.typeId,
    required this.family,
    required this.kind,
    required this.tags,
  });

  final String id;
  final String title;
  final String subtitle;
  final String typeId;
  final LibraryDeviceFamily family;
  final LibraryInstrumentKind kind;
  final List<String> tags;
}

final class LibraryDeviceTypeItem extends LibraryDeviceBrowseItem {
  LibraryDeviceTypeItem({
    required DeviceDefinition definition,
  }) : super(
          id: 'device:${definition.typeId}',
          title: definition.picker.name,
          subtitle: definition.picker.description,
          typeId: definition.typeId,
          family: libraryDeviceFamilyForType(definition.typeId),
          kind: libraryInstrumentKindForType(definition.typeId),
          tags: definition.picker.libraryTags,
        );

  DeviceDefinition get definition =>
      deviceDefinitionRepository.find(typeId)!;
}

final class LibraryDevicePresetBrowseItem extends LibraryDeviceBrowseItem {
  LibraryDevicePresetBrowseItem({
    required this.preset,
  }) : super(
          id: preset.id,
          title: preset.title,
          subtitle: preset.subtitle.isEmpty
              ? preset.deviceType
              : '${preset.subtitle} · ${preset.deviceType}',
          typeId: preset.deviceType,
          family: libraryDeviceFamilyForType(preset.deviceType),
          kind: libraryInstrumentKindForType(preset.deviceType),
          tags: preset.tags,
        );

  final LibraryPresetItem preset;
}

abstract final class LibraryDeviceCatalog {
  static List<LibraryDeviceBrowseItem> itemsFor({
    required LibraryDeviceFamily family,
    LibraryManifest? manifest,
    LibraryInstrumentKind? kindFilter,
    String? typeFilter,
    Set<String> tags = const {},
    bool percussionOnly = false,
  }) {
    final out = <LibraryDeviceBrowseItem>[];

    for (final definition in deviceDefinitionRepository.definitions) {
      final typeId = definition.typeId;
      if (libraryDeviceFamilyForType(typeId) != family) continue;
      if (percussionOnly &&
          libraryInstrumentKindForType(typeId) != LibraryInstrumentKind.drum) {
        continue;
      }
      if (kindFilter != null &&
          family == LibraryDeviceFamily.instrument &&
          libraryInstrumentKindForType(typeId) != kindFilter) {
        continue;
      }
      if (typeFilter != null && typeId != typeFilter) continue;
      final item = LibraryDeviceTypeItem(definition: definition);
      if (tags.isNotEmpty &&
          !tags.every((t) => item.tags.contains(t))) {
        // Device types without tags still pass when filtering presets mainly;
        // require tag intersection only if the device declares tags.
        if (item.tags.isNotEmpty &&
            item.tags.toSet().intersection(tags).isEmpty) {
          continue;
        }
      }
      out.add(item);
    }

    for (final preset in LibraryCatalog.presetItems(manifest)) {
      if (libraryDeviceFamilyForType(preset.deviceType) != family) continue;
      if (percussionOnly &&
          libraryInstrumentKindForType(preset.deviceType) !=
              LibraryInstrumentKind.drum) {
        continue;
      }
      if (kindFilter != null &&
          family == LibraryDeviceFamily.instrument &&
          libraryInstrumentKindForType(preset.deviceType) != kindFilter) {
        continue;
      }
      if (typeFilter != null && preset.deviceType != typeFilter) continue;
      if (tags.isNotEmpty &&
          tags.intersection(preset.tags.toSet()).isEmpty) {
        continue;
      }
      out.add(LibraryDevicePresetBrowseItem(preset: preset));
    }

    out.sort((a, b) {
      final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      if (byTitle != 0) return byTitle;
      // Device types before presets with same title.
      final aRank = a is LibraryDeviceTypeItem ? 0 : 1;
      final bRank = b is LibraryDeviceTypeItem ? 0 : 1;
      return aRank.compareTo(bRank);
    });
    return out;
  }

  static List<String> deviceTypesInFamily(LibraryDeviceFamily family) {
    return deviceDefinitionRepository.definitions
        .where((d) => libraryDeviceFamilyForType(d.typeId) == family)
        .map((d) => d.typeId)
        .toList()
      ..sort();
  }

  static List<String> tagsInFamily(
    LibraryDeviceFamily family, {
    LibraryManifest? manifest,
  }) {
    final tags = <String>{};
    for (final d in deviceDefinitionRepository.definitions) {
      if (libraryDeviceFamilyForType(d.typeId) != family) continue;
      tags.addAll(d.picker.libraryTags);
    }
    for (final p in LibraryCatalog.presetItems(manifest)) {
      if (libraryDeviceFamilyForType(p.deviceType) != family) continue;
      tags.addAll(p.tags);
    }
    final list = tags.toList()..sort();
    return list;
  }
}
