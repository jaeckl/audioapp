import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_metrics.dart';
import 'sampler_device_strip.dart';

class DeviceStrip extends StatelessWidget {
  const DeviceStrip({
    super.key,
    required this.track,
    required this.samples,
    required this.onSamplerParameterChanged,
    required this.onAssignSamplerSample,
    required this.onOpenSamplerEditor,
    required this.onPreviewSample,
    required this.onImportSamples,
    required this.onFrequencyChanged,
  });

  final TrackSnapshot? track;
  final List<SampleLibraryEntrySnapshot> samples;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(String deviceId, String sampleId) onAssignSamplerSample;
  final void Function(TrackSnapshot track, DeviceSnapshot device) onOpenSamplerEditor;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewSample;
  final Future<List<SampleLibraryEntrySnapshot>> Function() onImportSamples;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;

  SampleLibraryEntrySnapshot? _sampleForDevice(DeviceSnapshot device) {
    if (device.sampleId.isEmpty) {
      return null;
    }
    for (final sample in samples) {
      if (sample.id == device.sampleId) {
        return sample;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DeviceStripMetrics.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF121218),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: track == null ? _emptyState(context) : _trackDevices(context, track!),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Text(
        'Select a track to show devices',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white38),
      ),
    );
  }

  Widget _trackDevices(BuildContext context, TrackSnapshot track) {
    final sampler = track.samplerDevice;
    if (sampler != null) {
      return SamplerDeviceStrip(
        trackName: track.name,
        device: sampler,
        sample: _sampleForDevice(sampler),
        onParameterChanged: (parameterId, value) =>
            onSamplerParameterChanged(sampler.id, parameterId, value),
        onOpenFullscreen: () => onOpenSamplerEditor(track, sampler),
      );
    }

    final oscillator = track.oscillatorDevice;
    if (oscillator == null) {
      return Center(
        child: Text(
          'No instrument on ${track.name}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Oscillator — ${track.name}', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${oscillator.frequencyHz.round()} Hz'),
              Expanded(
                child: Slider(
                  min: 110,
                  max: 880,
                  divisions: 14,
                  value: oscillator.frequencyHz.clamp(110, 880),
                  label: '${oscillator.frequencyHz.round()} Hz',
                  onChanged: (value) => onFrequencyChanged(oscillator.id, value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
