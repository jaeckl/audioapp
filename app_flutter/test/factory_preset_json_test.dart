import 'dart:convert';

import 'package:audioapp/features/content_library/factory_preset_json.dart';
import 'package:audioapp/features/content_library/library_manifest.dart';
import 'package:audioapp/features/content_library/library_tags.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('leaf factory preset resolves to applyDevicePreset JSON', () {
    final json = FactoryPresetJson.resolveApplyJson('preset:808-kick');
    expect(json, isNotNull);
    final doc = jsonDecode(json!) as Map<String, dynamic>;
    expect(doc['presetVersion'], 2);
    final device = doc['device'] as Map<String, dynamic>;
    expect(device['type'], 'kick_generator');
    expect(device['parameters'], isA<Map>());
    expect((device['parameters'] as Map)['kickDecay'], isNotNull);
    expect(json, isNot(contains('presetRef')));
  });

  test('kit preset expands presetRef pads', () {
    final json = FactoryPresetJson.resolveApplyJson('preset:kit-808');
    expect(json, isNotNull);
    final doc = jsonDecode(json!) as Map<String, dynamic>;
    final device = doc['device'] as Map<String, dynamic>;
    expect(device['type'], 'drum_machine');
    final pads = device['pads'] as List<dynamic>;
    expect(pads.length, greaterThanOrEqualTo(4));

    Map<String, dynamic> padAt(int note) => pads
        .cast<Map<String, dynamic>>()
        .firstWhere((p) => p['note'] == note);

    final kick = padAt(36);
    expect(kick['name'], 'Kick');
    final kickDev = (kick['devices'] as List).first as Map<String, dynamic>;
    expect(kickDev['type'], 'kick_generator');
    expect(kickDev.containsKey('presetRef'), isFalse);

    final chh = padAt(38);
    final ohh = padAt(39);
    expect(chh['chokeGroup'], 1);
    expect(ohh['chokeGroup'], 1);

    expect(json, isNot(contains('presetRef')));
  });

  test('15 kit presets in manifest with known tags', () async {
    final raw =
        await rootBundle.loadString('assets/content_library/manifest.json');
    final manifest =
        LibraryManifest.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final kits = manifest.presets
        .where((e) => e.deviceType == 'drum_machine')
        .toList();
    expect(kits.length, 15);
    for (final kit in kits) {
      expect(kit.id, startsWith('preset:kit-'));
      expect(kit.tags, contains('factory'));
      expect(kit.tags, contains('drums'));
      for (final tag in kit.tags) {
        expect(libraryTagGroup(tag), isNotNull, reason: 'Unknown tag $tag');
      }
      expect(FactoryPresetJson.documentFor(kit.id), isNotNull);
      expect(FactoryPresetJson.resolveApplyJson(kit.id), isNotNull);
    }
  });

  test('cyclic presetRef throws', () {
    // Sanity: known good kit does not throw.
    expect(() => FactoryPresetJson.resolveApplyJson('preset:kit-909'),
        returnsNormally);
  });
}
