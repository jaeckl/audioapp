import 'package:flutter/material.dart';

import '../../bridge/device_capabilities.dart';
import '../../devices/device_repository.dart';
import 'library_theme.dart';

/// Top-level rail categories when [LibraryBrowseMode.devices] is active.
enum LibraryDeviceFamily {
  instrument,
  audioFx,
  noteFx,
}

extension LibraryDeviceFamilyLabels on LibraryDeviceFamily {
  String get title => switch (this) {
        LibraryDeviceFamily.instrument => 'Instrument',
        LibraryDeviceFamily.audioFx => 'Audio FX',
        LibraryDeviceFamily.noteFx => 'Note FX',
      };

  String get subtitle => switch (this) {
        LibraryDeviceFamily.instrument => 'Synths, drums, samplers',
        LibraryDeviceFamily.audioFx => 'Inserts & processors',
        LibraryDeviceFamily.noteFx => 'MIDI processors',
      };

  IconData get icon => switch (this) {
        LibraryDeviceFamily.instrument => Icons.piano,
        LibraryDeviceFamily.audioFx => Icons.graphic_eq,
        LibraryDeviceFamily.noteFx => Icons.schedule,
      };

  Color get accent => switch (this) {
        LibraryDeviceFamily.instrument => LibraryTheme.accent,
        LibraryDeviceFamily.audioFx => const Color(0xFF00FF33),
        LibraryDeviceFamily.noteFx => const Color(0xFFF9FF00),
      };
}

/// Coarse kind used as the first sub-filter for instruments.
enum LibraryInstrumentKind {
  synth,
  drum,
  sampler,
  other,
}

extension LibraryInstrumentKindLabels on LibraryInstrumentKind {
  String get title => switch (this) {
        LibraryInstrumentKind.synth => 'Synth',
        LibraryInstrumentKind.drum => 'Drum',
        LibraryInstrumentKind.sampler => 'Sampler',
        LibraryInstrumentKind.other => 'Other',
      };
}

LibraryDeviceFamily libraryDeviceFamilyForType(String typeId) {
  if (DeviceCapabilities.noteFx.contains(typeId)) {
    return LibraryDeviceFamily.noteFx;
  }
  if (DeviceCapabilities.audioFx.contains(typeId)) {
    return LibraryDeviceFamily.audioFx;
  }
  final category =
      deviceDefinitionRepository.find(typeId)?.picker.category ?? '';
  if (category == 'Instruments' ||
      DeviceCapabilities.virtualStripHosts.contains(typeId) ||
      typeId.endsWith('_generator') ||
      typeId == 'drum_machine') {
    return LibraryDeviceFamily.instrument;
  }
  // Routing / analysis / containers — treat as audio FX for browse.
  return LibraryDeviceFamily.audioFx;
}

LibraryInstrumentKind libraryInstrumentKindForType(String typeId) {
  if (typeId == 'simple_sampler' || typeId == 'granular_formant_synth') {
    return LibraryInstrumentKind.sampler;
  }
  if (typeId == 'drum_machine' || typeId.endsWith('_generator')) {
    return LibraryInstrumentKind.drum;
  }
  if (DeviceCapabilities.virtualStripHosts.contains(typeId) ||
      deviceDefinitionRepository.find(typeId)?.picker.category ==
          'Instruments') {
    return LibraryInstrumentKind.synth;
  }
  return LibraryInstrumentKind.other;
}
