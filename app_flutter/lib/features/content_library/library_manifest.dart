import 'dart:convert';

import 'package:flutter/services.dart';

part 'library_manifest_library_preset_manifest_entry.dart';
part 'library_manifest_library_midi_clip_manifest_entry.dart';

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
    final raw =
        await rootBundle.loadString('assets/content_library/manifest.json');
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
          .map((e) =>
              LibraryPresetManifestEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      midiClips: midiJson
          .map((e) =>
              LibraryMidiClipManifestEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
