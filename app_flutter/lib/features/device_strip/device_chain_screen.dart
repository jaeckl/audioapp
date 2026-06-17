import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_chain_row.dart';
import 'device_strip_slot.dart';
import 'sampler_device_panel.dart';

/// Fullscreen horizontally scrollable device chain for the selected track.
class DeviceChainScreen extends StatelessWidget {
  const DeviceChainScreen({
    super.key,
    required this.track,
    required this.samples,
    required this.playing,
    required this.onSamplerParameterChanged,
    required this.onOpenSamplerEditor,
    required this.onFrequencyChanged,
    required this.onInsertDevice,
    this.onSamplerTabChanged,
    this.samplerTabFor,
  });

  final TrackSnapshot track;
  final List<SampleLibraryEntrySnapshot> samples;
  final bool playing;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(TrackSnapshot track, DeviceSnapshot device) onOpenSamplerEditor;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;
  final void Function(int insertIndex) onInsertDevice;
  final void Function(String deviceId, SamplerDeviceTab tab)? onSamplerTabChanged;
  final SamplerDeviceTab Function(String deviceId)? samplerTabFor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A22),
        title: Text('${track.name} · Devices'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Swipe horizontally · tap + to insert · tap device to edit',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white38),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: DeviceChainRow(
                  track: track,
                  samples: samples,
                  playing: playing,
                  density: DeviceStripSlotDensity.fullscreen,
                  samplerTabFor: samplerTabFor,
                  onSamplerParameterChanged: onSamplerParameterChanged,
                  onOpenSamplerEditor: onOpenSamplerEditor,
                  onFrequencyChanged: onFrequencyChanged,
                  onInsertDevice: onInsertDevice,
                  onSamplerTabChanged: onSamplerTabChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
