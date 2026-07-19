import 'dart:convert';

import 'package:audioapp/features/content_library/library_manifest.dart';
import 'package:audioapp/features/content_library/library_tags.dart';
import 'package:audioapp/features/device_strip/device_preset_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _drumDeviceTypes = {
  'kick_generator',
  'snare_generator',
  'clap_generator',
  'hihat_generator',
  'rimshot_generator',
  'tom_generator',
  'ride_generator',
  'crash_generator',
};

const _families = {
  '808',
  '909',
  'electro',
  'trap',
  'boombap',
  'house',
  'techno',
  'pop',
  'rnb',
  'reggae',
  'rock',
  'breakbeat',
  'disco',
  'dnb',
  'ambient',
};

const _coreVoices = {'kick', 'snare', 'chh', 'ohh'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('drum family presets resolve in DevicePresetStore', () async {
    final raw =
        await rootBundle.loadString('assets/content_library/manifest.json');
    final manifest = LibraryManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    final drumPresets = manifest.presets
        .where((e) => _drumDeviceTypes.contains(e.deviceType))
        .toList();

    expect(drumPresets.length, 112);

    for (final entry in drumPresets) {
      final preset = DevicePresetStore.find(entry.deviceType, entry.id);
      expect(preset, isNotNull, reason: 'Missing store entry for ${entry.id}');
      expect(preset!.params, isNotEmpty);
      expect(entry.tags, contains('factory'));
      expect(
        entry.tags.any(_families.contains),
        isTrue,
        reason: '${entry.id} missing family tag',
      );
      for (final tag in entry.tags) {
        expect(libraryTagGroup(tag), isNotNull, reason: 'Unknown tag $tag');
      }
    }
  });

  test('each family ships core Kick Snare CHH OHH', () async {
    final raw =
        await rootBundle.loadString('assets/content_library/manifest.json');
    final manifest = LibraryManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final ids = manifest.presets.map((e) => e.id).toSet();

    for (final family in _families) {
      for (final voice in _coreVoices) {
        final id = 'preset:$family-$voice';
        expect(ids, contains(id), reason: 'Missing $id');
        final deviceType = voice == 'kick'
            ? 'kick_generator'
            : voice == 'snare'
                ? 'snare_generator'
                : 'hihat_generator';
        expect(DevicePresetStore.find(deviceType, id), isNotNull);
      }
    }
  });

  test('crash filter device type has presets', () async {
    final raw =
        await rootBundle.loadString('assets/content_library/manifest.json');
    final manifest = LibraryManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final crashes =
        manifest.presets.where((e) => e.deviceType == 'crash_generator');
    expect(crashes.length, greaterThanOrEqualTo(5));
  });
}
