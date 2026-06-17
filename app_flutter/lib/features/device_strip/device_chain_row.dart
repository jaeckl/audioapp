import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_chain_separator.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';
import 'sampler_device_panel.dart';

/// Horizontally scrollable Bitwig/Ableton-style device chain row.
class DeviceChainRow extends StatelessWidget {
  const DeviceChainRow({
    super.key,
    required this.track,
    required this.samples,
    required this.playing,
    required this.density,
    required this.onSamplerParameterChanged,
    required this.onOpenSamplerEditor,
    required this.onFrequencyChanged,
    required this.onInsertDevice,
    this.onSamplerTabChanged,
    this.onExpand,
    this.onCollapse,
    this.samplerTabFor,
  });

  final TrackSnapshot track;
  final List<SampleLibraryEntrySnapshot> samples;
  final bool playing;
  final DeviceStripSlotDensity density;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(TrackSnapshot track, DeviceSnapshot device) onOpenSamplerEditor;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;
  final void Function(int insertIndex) onInsertDevice;
  final void Function(String deviceId, SamplerDeviceTab tab)? onSamplerTabChanged;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;
  final SamplerDeviceTab Function(String deviceId)? samplerTabFor;

  double get _rowHeight => switch (density) {
        DeviceStripSlotDensity.fullscreen => DeviceStripMetrics.fullscreenHeight,
        DeviceStripSlotDensity.collapsed => DeviceStripMetrics.collapsedHeight,
        DeviceStripSlotDensity.strip => DeviceStripMetrics.height,
      };

  SampleLibraryEntrySnapshot? _sampleFor(DeviceSnapshot device) {
    if (device.sampleId.isEmpty) return null;
    for (final sample in samples) {
      if (sample.id == device.sampleId) return sample;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final devices = track.visibleDevices.toList();

    return SizedBox(
      height: _rowHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          children: [
            if (devices.isEmpty)
              _leadingInsert(context)
            else
              for (var i = 0; i < devices.length; i++) ...[
                DeviceStripSlot(
                  track: track,
                  device: devices[i],
                  sample: _sampleFor(devices[i]),
                  density: density,
                  samplerTab: samplerTabFor?.call(devices[i].id) ?? SamplerDeviceTab.sample,
                  onSamplerParameterChanged: (parameterId, value) =>
                      onSamplerParameterChanged(devices[i].id, parameterId, value),
                  onOpenSamplerEditor: () => onOpenSamplerEditor(track, devices[i]),
                  onFrequencyChanged: (value) =>
                      onFrequencyChanged(devices[i].id, value),
                  onSamplerTabChanged: onSamplerTabChanged == null
                      ? null
                      : (tab) => onSamplerTabChanged!(devices[i].id, tab),
                  onExpand: onExpand,
                  onCollapse: onCollapse,
                ),
                DeviceChainSeparator(
                  active: playing,
                  gain: devices[i].chainVuGain,
                  onInsert: () => onInsertDevice(
                    deviceInsertIndexAfter(track, i),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _leadingInsert(BuildContext context) {
    return SizedBox(
      width: DeviceStripMetrics.separatorWidth + 120,
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'No devices',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white38),
              ),
            ),
          ),
          DeviceChainSeparator(
            active: playing,
            gain: 0.35,
            onInsert: () => onInsertDevice(0),
          ),
        ],
      ),
    );
  }
}
