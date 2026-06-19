import 'dart:convert';

import 'package:flutter/services.dart';

/// Bundled content library manifest (`assets/content_library/manifest.json`).
class LibraryManifest {
  LibraryManifest({
    required this.presets,
    required this.midiClips,
  });

  final List<LibraryPresetManifestEntry> presets;
  final List<LibraryMidiClipManifestEntry> midiClips;

  static LibraryManifest? _cached;

  static Future<LibraryManifest> load() async {
    if (_cached != null) {
      return _cached!;
    }
    final raw = await rootBundle.loadString('assets/content_library/manifest.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _cached = LibraryManifest.fromJson(map);
    return _cached!;
  }

  static void resetForTest() {
    _cached = null;
  }

  factory LibraryManifest.fromJson(Map<String, dynamic> json) {
    final presetsJson = json['presets'] as List<dynamic>? ?? [];
    final midiJson = json['midiClips'] as List<dynamic>? ?? [];
    return LibraryManifest(
      presets: presetsJson
          .map((e) => LibraryPresetManifestEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      midiClips: midiJson
          .map((e) => LibraryMidiClipManifestEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

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
