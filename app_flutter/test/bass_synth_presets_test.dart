import 'package:audioapp/features/content_library/factory_preset_json.dart';
import 'package:audioapp/features/device_strip/bass_synth_presets.dart';
import 'package:audioapp/features/device_strip/device_preset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  test('bass synth ships 40 factory presets', () {
    expect(BassSynthPresets.presets.length, 40);
  });

  test('bass preset resolves to applyDevicePreset JSON with FX/LFO', () {
    final json = FactoryPresetJson.resolveApplyJson('preset:bass-dub-wobble');
    expect(json, isNotNull);
    final doc = jsonDecode(json!) as Map<String, dynamic>;
    expect(doc['presetVersion'], 2);
    final device = doc['device'] as Map<String, dynamic>;
    expect(device['type'], 'bass_synth');
    expect((device['audioFxDevices'] as List).length, greaterThanOrEqualTo(1));
    expect((doc['modulators'] as List).length, 1);
    expect((doc['modEdges'] as List).length, greaterThanOrEqualTo(1));
    expect(FactoryPresetJson.deviceTypeFor('preset:bass-dub-wobble'), 'bass_synth');
  });

  test('bass compressor FX uses dynamics input panel', () {
    final doc = FactoryPresetJson.documentFor('preset:bass-808-boom');
    expect(doc, isNotNull);
    final fx = (doc!['device'] as Map)['audioFxDevices'] as List;
    final comps = fx.whereType<Map>().where((d) => d['type'] == 'compressor');
    expect(comps, isNotEmpty);
    for (final c in comps) {
      expect((c['inputPanel'] as Map)['type'], 'dynamics');
    }
  });

  test('bass store flat params available for preview', () {
    final preset =
        DevicePresetStore.find('bass_synth', 'preset:bass-sub-foundation');
    expect(preset, isNotNull);
    expect(preset!.params['bassOscShape'], isNotNull);
  });

  test('every bass preset document resolves', () {
    for (final id in BassSynthPresets.presets.keys) {
      expect(FactoryPresetJson.documentFor(id), isNotNull, reason: id);
      expect(FactoryPresetJson.resolveApplyJson(id), isNotNull, reason: id);
    }
  });
}
