part of 'library_manifest.dart';

class LibraryPresetManifestEntry {
  const LibraryPresetManifestEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.deviceType,
    required this.tags,
  });

  final String id;
  final String title;
  final String subtitle;
  final String deviceType;
  final List<String> tags;

  factory LibraryPresetManifestEntry.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'] as List<dynamic>? ?? [];
    return LibraryPresetManifestEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      deviceType: json['deviceType'] as String? ?? '',
      tags: tagsRaw.map((t) => t.toString()).toList(),
    );
  }
}
