import 'package:audioapp/features/content_library/factory_preset_json.dart';
import 'package:audioapp/features/device_strip/device_preset_store.dart';
import 'package:audioapp/features/device_strip/phase_mod_synth_presets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  test('phase mod synth ships 61 factory presets', () {
    expect(PhaseModSynthPresets.presets.length, 61);
  });

  test('phase mod preset resolves to applyDevicePreset JSON', () {
    final json = FactoryPresetJson.resolveApplyJson('preset:pm-digi-bell');
    expect(json, isNotNull);
    final doc = jsonDecode(json!) as Map<String, dynamic>;
    expect(doc['presetVersion'], 2);
    final device = doc['device'] as Map<String, dynamic>;
    expect(device['type'], 'phase_mod_synth');
    expect((device['parameters'] as Map)['pmAlgoIndex'], isNotNull);
    expect(
      FactoryPresetJson.deviceTypeFor('preset:pm-digi-bell'),
      'phase_mod_synth',
    );
  });

  test('phase mod store flat params available for preview', () {
    final preset =
        DevicePresetStore.find('phase_mod_synth', 'preset:pm-deep-bass');
    expect(preset, isNotNull);
    expect(preset!.params['pmOp1Level'], isNotNull);
  });

  test('every phase mod preset document resolves', () {
    for (final id in PhaseModSynthPresets.presets.keys) {
      expect(FactoryPresetJson.documentFor(id), isNotNull, reason: id);
      expect(FactoryPresetJson.resolveApplyJson(id), isNotNull, reason: id);
    }
  });
}
