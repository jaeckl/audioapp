import 'library_category.dart';

/// Describes what the content library should show when opened for a device.
///
/// Each device type can register its own [LibraryFilter] via
/// [DeviceLibraryRegistry] to control which category, tags, or resource
/// type are pre-selected when the library is opened from that device.
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

/// Registry mapping device types to their preferred library filter.
///
/// Add an entry here when a device type should open a specific library
/// category (e.g. wavetables, audio clips) instead of the default presets.
class DeviceLibraryRegistry {
  static const Map<String, LibraryFilter> _custom = {
    'simple_sampler': LibraryFilter(
      deviceType: 'simple_sampler',
      defaultCategory: LibraryCategory.audioClips,
    ),
    'granular_formant_synth': LibraryFilter(
      deviceType: 'granular_formant_synth',
      defaultCategory: LibraryCategory.audioClips,
    ),
    'wavetable_synth': LibraryFilter(
      deviceType: 'wavetable_synth',
      defaultCategory: LibraryCategory.wavetables,
      tags: ['factory'],
    ),
  };

  static LibraryFilter filterForDeviceType(String deviceType) =>
      _custom[deviceType] ?? LibraryFilter(
        deviceType: deviceType,
        defaultCategory: LibraryCategory.devicePresets,
      );
}
