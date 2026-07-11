import 'package:flutter/material.dart';
import '../../bridge/device_capabilities.dart';
import '../../devices/device_repository.dart';

enum DevicePickerRole { any, noteFx, audioFx }

const noteFxDeviceTypes = DeviceCapabilities.noteFx;
const audioFxDeviceTypes = DeviceCapabilities.audioFx;

Future<String?> showVirtualFxPickerSheet(
  BuildContext context, {
  required DevicePickerRole role,
}) {
  final items = role == DevicePickerRole.noteFx
      ? const [
          (
            'midi_delay',
            'MIDI Delay',
            'Delay notes before the instrument',
            Icons.schedule
          )
        ]
      : const [
          ('gate', 'Gate', 'Noise gate', Icons.door_sliding),
          ('compressor', 'Compressor', 'Dynamics control', Icons.compress),
          ('expander', 'Expander', 'Downward expansion', Icons.unfold_more),
          ('limiter', 'Limiter', 'Brick-wall limiting', Icons.horizontal_rule),
          ('filter', 'Filter', 'Multimode filtering', Icons.equalizer),
          ('four_band_eq', '4-Band EQ', 'Tone shaping', Icons.tune),
          (
            'frequency_shifter',
            'Ring Mod',
            'Frequency shifting',
            Icons.swap_horiz
          ),
          (
            'resonator_bank',
            'RESONATE',
            'Resonator bank',
            Icons.multiline_chart
          ),
          ('delay', 'Delay', 'Echo effect', Icons.timer),
          ('reverb', 'Reverb', 'Space and ambience', Icons.waves),
          ('chorus', 'Chorus', 'Width and motion', Icons.blur_circular),
          ('phaser', 'Phaser', 'Swept phase effect', Icons.flip_to_back),
          ('bitcrusher', 'Bitcrusher', 'Lo-fi reduction', Icons.blur_on),
          ('distortion', 'Distortion', 'Waveshaping drive', Icons.waves),
          ('tremolo', 'Tremolo', 'Amplitude modulation', Icons.blur_circular),
          ('stutter_fx', 'Stutter', 'Rhythmic buffer repeat', Icons.repeat),
        ];
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A1A22),
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
                role == DevicePickerRole.noteFx
                    ? 'Insert Note FX'
                    : 'Insert Audio FX',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final item in items)
            ListTile(
              leading: Icon(item.$4,
                  color: role == DevicePickerRole.noteFx
                      ? const Color(0xFFF9FF00)
                      : const Color(0xFF00FF33)),
              title: Text(item.$2),
              subtitle: Text(item.$3),
              onTap: () => Navigator.pop(context, item.$1),
            ),
        ],
      ),
    ),
  );
}

/// Bottom sheet to pick a device type when inserting into the chain.
Future<String?> showDevicePickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF1A1A22),
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  'Insert device',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final definition in deviceDefinitionRepository.definitions
                  .where((item) => item.picker.category == 'Instruments'))
                ListTile(
                  leading: Icon(definition.picker.icon,
                      color: definition.picker.color),
                  title: Text(definition.picker.name),
                  subtitle: Text(definition.picker.description),
                  onTap: () => Navigator.pop(context, definition.typeId),
                ),
              ListTile(
                leading: const Icon(Icons.account_tree_outlined,
                    color: Color(0xFF62C7B5)),
                title: const Text('Chain'),
                subtitle: const Text('Virtual device strip · mix & gain'),
                onTap: () => Navigator.pop(context, 'device_chain'),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'Effects',
                  style: TextStyle(
                    color: Color(0xFF9A9AA8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              for (final definition in deviceDefinitionRepository.definitions
                  .where((item) => item.picker.category == 'Effects'))
                ListTile(
                  leading: Icon(definition.picker.icon,
                      color: definition.picker.color),
                  title: Text(definition.picker.name),
                  subtitle: Text(definition.picker.description),
                  onTap: () => Navigator.pop(context, definition.typeId),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'Frequency Effects',
                  style: TextStyle(
                    color: Color(0xFF9A9AA8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              for (final definition in deviceDefinitionRepository.definitions
                  .where((item) => item.picker.category == 'Frequency Effects'))
                ListTile(
                  leading: Icon(definition.picker.icon,
                      color: definition.picker.color),
                  title: Text(definition.picker.name),
                  subtitle: Text(definition.picker.description),
                  onTap: () => Navigator.pop(context, definition.typeId),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text('Routing',
                    style: TextStyle(
                      color: Color(0xFF9A9AA8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    )),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text('Analysis & Metering',
                    style: TextStyle(
                        color: Color(0xFF9A9AA8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6)),
              ),
              for (final item in const [
                (
                  'oscilloscope',
                  'Oscilloscope',
                  'Waveform · trigger view',
                  Icons.monitor_heart_outlined
                ),
                (
                  'spectrum_analyzer',
                  'Spectrum Analyzer',
                  'Frequency energy · 20 Hz–20 kHz',
                  Icons.equalizer
                ),
                (
                  'loudness_meter',
                  'Loudness Meter',
                  'LUFS · integrated · true peak',
                  Icons.speed
                ),
                (
                  'stereo_imager',
                  'Stereo Imager',
                  'Vectorscope · phase correlation',
                  Icons.blur_circular
                ),
              ])
                ListTile(
                  leading: Icon(item.$4, color: const Color(0xFF57D3C4)),
                  title: Text(item.$2),
                  subtitle: Text(item.$3),
                  onTap: () => Navigator.pop(context, item.$1),
                ),
              ListTile(
                leading:
                    const Icon(Icons.call_received, color: Color(0xFF66D19E)),
                title: const Text('Audio Receiver'),
                subtitle: const Text('Receive any device audio output'),
                onTap: () => Navigator.pop(context, 'audio_receiver'),
              ),
              ListTile(
                leading:
                    const Icon(Icons.call_received, color: Color(0xFFF08BB4)),
                title: const Text('MIDI Receiver'),
                subtitle: const Text('Receive notes from any track MIDI input'),
                onTap: () => Navigator.pop(context, 'midi_receiver'),
              ),
              ListTile(
                leading: const Icon(Icons.schedule, color: Color(0xFFA78BFA)),
                title: const Text('MIDI Delay'),
                subtitle:
                    const Text('Delay notes in seconds or tempo divisions'),
                onTap: () => Navigator.pop(context, 'midi_delay'),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'Time‑Based Effects',
                  style: TextStyle(
                    color: Color(0xFF9A9AA8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              for (final definition in deviceDefinitionRepository.definitions
                  .where(
                      (item) => item.picker.category == 'Time-Based Effects'))
                ListTile(
                  leading: Icon(definition.picker.icon,
                      color: definition.picker.color),
                  title: Text(definition.picker.name),
                  subtitle: Text(definition.picker.description),
                  onTap: () => Navigator.pop(context, definition.typeId),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'Mood Effects',
                  style: TextStyle(
                    color: Color(0xFF9A9AA8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              for (final definition in deviceDefinitionRepository.definitions
                  .where((item) => item.picker.category == 'Mood Effects'))
                ListTile(
                  leading: Icon(definition.picker.icon,
                      color: definition.picker.color),
                  title: Text(definition.picker.name),
                  subtitle: Text(definition.picker.description),
                  onTap: () => Navigator.pop(context, definition.typeId),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
