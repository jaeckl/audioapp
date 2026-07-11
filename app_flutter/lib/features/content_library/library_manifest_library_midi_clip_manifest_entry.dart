part of 'library_manifest.dart';

class LibraryMidiClipManifestEntry {
  const LibraryMidiClipManifestEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.patternId,
    required this.tags,
  });

  final String id;
  final String title;
  final String subtitle;
  final String patternId;
  final List<String> tags;

  factory LibraryMidiClipManifestEntry.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'] as List<dynamic>? ?? [];
    return LibraryMidiClipManifestEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      patternId: json['patternId'] as String? ?? '',
      tags: tagsRaw.map((t) => t.toString()).toList(),
    );
  }
}
