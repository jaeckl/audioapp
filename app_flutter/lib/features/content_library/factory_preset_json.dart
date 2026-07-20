import 'dart:convert';

import '../device_strip/device_preset_store.dart';
import '../device_strip/bass_synth_presets.dart';
import '../device_strip/phase_mod_synth_presets.dart';

part 'factory_preset_kits.dart';

/// Factory preset documents in engine `applyDevicePreset` JSON form.
///
/// Leaves are built from [DevicePresetStore]. Kits / nests may use
/// `presetRef` nodes that resolve to another factory preset's `device` blob.
/// Bass / phase-mod synth presets ship docs via their preset classes.
abstract final class FactoryPresetJson {
  static const presetVersion = 2;

  /// Unresolved document for [presetId], or null if unknown.
  static Map<String, dynamic>? documentFor(String presetId) {
    final bass = BassSynthPresets.documentFor(presetId);
    if (bass != null) return bass;

    final phaseMod = PhaseModSynthPresets.documentFor(presetId);
    if (phaseMod != null) return phaseMod;

    final kit = _kitDocuments[presetId];
    if (kit != null) return kit;

    final leaf = _leafDocument(presetId);
    if (leaf != null) return leaf;
    return null;
  }

  /// Fully resolved JSON string ready for [EngineBridge.applyDevicePreset].
  static String? resolveApplyJson(String presetId) {
    final doc = documentFor(presetId);
    if (doc == null) return null;
    final resolved = _resolveNode(Map<String, dynamic>.from(doc), <String>{});
    if (resolved is! Map<String, dynamic>) return null;
    return jsonEncode(resolved);
  }

  /// Flat params for legacy [previewPreset].
  /// Kits preview via that family's kick voice.
  static Map<String, double>? flatParamsForPreview(String presetId) {
    if (_kitDocuments.containsKey(presetId)) {
      final family = presetId.substring('preset:kit-'.length);
      return DevicePresetStore.find('kick_generator', 'preset:$family-kick')
          ?.params;
    }
    final type = deviceTypeFor(presetId);
    if (type == null || type == 'drum_machine') return null;
    return DevicePresetStore.find(type, presetId)?.params;
  }

  /// Device type to send to [previewPreset] (kits → kick_generator).
  static String? previewDeviceType(String presetId) {
    if (_kitDocuments.containsKey(presetId)) return 'kick_generator';
    return deviceTypeFor(presetId);
  }

  static String? deviceTypeFor(String presetId) {
    if (BassSynthPresets.presets.containsKey(presetId)) return 'bass_synth';
    if (PhaseModSynthPresets.presets.containsKey(presetId)) {
      return 'phase_mod_synth';
    }
    if (_kitDocuments.containsKey(presetId)) return 'drum_machine';
    // Subtractive stays out of _leafTypes so apply still uses
    // applySubtractiveSynthPreset (LFO/mod), not bare leaf JSON.
    if (DevicePresetStore.find('subtractive_synth', presetId) != null) {
      return 'subtractive_synth';
    }
    for (final type in _leafTypes) {
      if (DevicePresetStore.find(type, presetId) != null) return type;
    }
    return null;
  }

  /// Device types that have a real engine preview renderer.
  /// FX / unknown stay silent (no fake sine for device presets).
  static bool supportsAudioPreview(String? deviceType) {
    if (deviceType == null || deviceType.isEmpty) return false;
    switch (deviceType) {
      case 'subtractive_synth':
      case 'bass_synth':
      case 'phase_mod_synth':
      case 'simple_oscillator':
      case 'simple_sampler':
      case 'kick_generator':
        return true;
      default:
        // Kits preview as kick_generator via previewDeviceType.
        // Other percussion generators stay silent until engine renderers exist.
        return false;
    }
  }

  static bool isFactoryPreset(String presetId) => documentFor(presetId) != null;

  static const _leafTypes = [
    'kick_generator',
    'snare_generator',
    'clap_generator',
    'hihat_generator',
    'rimshot_generator',
    'tom_generator',
    'ride_generator',
    'crash_generator',
    'simple_sampler',
    'simple_oscillator',
    'granular_formant_synth',
  ];

  static Map<String, dynamic>? _leafDocument(String presetId) {
    for (final type in _leafTypes) {
      final preset = DevicePresetStore.find(type, presetId);
      if (preset == null) continue;
      final parameters = <String, dynamic>{
        for (final e in preset.params.entries) e.key: e.value,
      };
      // String params (e.g. granular sampleId) live beside floats in engine JSON.
      for (final e in preset.stringParams.entries) {
        parameters[e.key] = e.value;
      }
      final device = <String, dynamic>{
        'id': 'factory',
        'type': type,
        'bypass': false,
        'parameters': parameters,
      };
      if (_monoDrumTypes.contains(type)) {
        device['outputPanel'] = {'type': 'mono', 'gain': 1.0};
        device['inputPanel'] = {'type': 'empty'};
      }
      return {
        'presetVersion': presetVersion,
        'device': device,
        'automationClips': <dynamic>[],
        'modEdges': <dynamic>[],
        'modulators': <dynamic>[],
      };
    }
    return null;
  }

  static const _monoDrumTypes = {
    'kick_generator',
    'snare_generator',
    'clap_generator',
    'hihat_generator',
    'rimshot_generator',
    'tom_generator',
    'ride_generator',
    'crash_generator',
  };

  static dynamic _resolveNode(dynamic node, Set<String> stack) {
    if (node is List) {
      return [for (final item in node) _resolveNode(item, stack)];
    }
    if (node is! Map) return node;

    final map = Map<String, dynamic>.from(node);
    final ref = map['presetRef'];
    if (ref is String) {
      if (stack.contains(ref)) {
        throw StateError('Cyclic presetRef: $ref');
      }
      final doc = documentFor(ref);
      if (doc == null) {
        throw StateError('Unknown presetRef: $ref');
      }
      stack.add(ref);
      final resolvedDoc =
          _resolveNode(Map<String, dynamic>.from(doc), stack) as Map<String, dynamic>;
      stack.remove(ref);
      final device = resolvedDoc['device'];
      if (device is! Map) {
        throw StateError('presetRef $ref missing device');
      }
      // Preserve sibling overrides on the ref node (e.g. future gain tweaks).
      final merged = Map<String, dynamic>.from(device);
      for (final e in map.entries) {
        if (e.key == 'presetRef') continue;
        merged[e.key] = _resolveNode(e.value, stack);
      }
      return merged;
    }

    return {
      for (final e in map.entries) e.key: _resolveNode(e.value, stack),
    };
  }
}
