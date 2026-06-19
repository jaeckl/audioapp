import 'dart:convert';

import 'package:audioapp/features/device_strip/subtractive_synth_presets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every subtractive synth manifest preset has full parameter bundle', () async {
    final raw = await rootBundle.loadString('assets/content_library/manifest.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final presets = json['presets'] as List<dynamic>;

    final synthIds = presets
        .cast<Map<String, dynamic>>()
        .where((p) => p['deviceType'] == 'subtractive_synth')
        .map((p) => p['id'] as String)
        .toList();

    expect(synthIds.length, greaterThanOrEqualTo(26));

    for (final id in synthIds) {
      final bundle = SubtractiveSynthPresets.presets[id];
      expect(bundle, isNotNull, reason: 'Missing preset bundle for $id');
      for (final key in SubtractiveSynthPresets.initParams.keys) {
        expect(
          bundle!.params.containsKey(key),
          isTrue,
          reason: '$id missing param $key',
        );
      }
      for (final mod in bundle!.mods) {
        expect(mod.lfoIndex, greaterThanOrEqualTo(0));
        expect(mod.lfoIndex, lessThan(bundle.lfos.length));
      }
    }
  });

  test('bass, lead, and pad presets are tagged distinctly', () async {
    final raw = await rootBundle.loadString('assets/content_library/manifest.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final presets = json['presets'] as List<dynamic>;

    final bass = presets
        .cast<Map<String, dynamic>>()
        .where((p) =>
            p['deviceType'] == 'subtractive_synth' &&
            (p['tags'] as List).contains('bass'))
        .toList();
    final leads = presets
        .cast<Map<String, dynamic>>()
        .where((p) =>
            p['deviceType'] == 'subtractive_synth' &&
            (p['tags'] as List).contains('lead'))
        .toList();
    final pads = presets
        .cast<Map<String, dynamic>>()
        .where((p) =>
            p['deviceType'] == 'subtractive_synth' &&
            (p['tags'] as List).contains('pad'))
        .toList();

    expect(bass.length, 10);
    expect(leads.length, 7);
    expect(pads.length, 5);
  });

  test('motion presets include LFO modulation routing', () {
    final warmPad = SubtractiveSynthPresets.presets['preset:synth-pad-warm']!;
    expect(warmPad.lfos, isNotEmpty);
    expect(warmPad.mods, isNotEmpty);

    final reese = SubtractiveSynthPresets.presets['preset:synth-bass-reese']!;
    expect(reese.lfos, isNotEmpty);
    expect(reese.mods.first.paramId, 'filterCutoff');

    final init = SubtractiveSynthPresets.presets['preset:synth-init']!;
    expect(init.lfos, isEmpty);
    expect(init.mods, isEmpty);

    final wobble = SubtractiveSynthPresets.presets['preset:synth-bass-wobble-classic']!;
    expect(wobble.lfos, isNotEmpty);
    expect(wobble.mods.any((m) => m.paramId == 'filterCutoff'), isTrue);
    expect(wobble.mods.first.amount, greaterThan(0.5));

    final growl = SubtractiveSynthPresets.presets['preset:synth-bass-wobble-growl']!;
    expect(growl.lfos.length, 2);
    expect(growl.mods.length, greaterThanOrEqualTo(2));
  });
}
