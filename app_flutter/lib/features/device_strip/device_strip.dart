import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_strip_metrics.dart';
import 'device_strip_viewport.dart';
import 'oscillator_device_panel.dart';
import 'sampler_device_panel.dart';
import 'sampler_device_strip.dart';

class DeviceStrip extends StatefulWidget {
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

  @override
  State<DeviceStrip> createState() => _DeviceStripState();
}

class _DeviceStripState extends State<DeviceStrip> {
  bool _expanded = false;
  SamplerDeviceTab _samplerTab = SamplerDeviceTab.sample;

  SampleLibraryEntrySnapshot? _sampleForDevice(DeviceSnapshot device) {
    if (device.sampleId.isEmpty) {
      return null;
    }
    for (final sample in widget.samples) {
      if (sample.id == device.sampleId) {
        return sample;
      }
    }
    return null;
  }

  bool _shouldStartCollapsed(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.height < 720 || size.width < 400;
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = !_expanded && _shouldStartCollapsed(context);
    final stripHeight =
        collapsed ? DeviceStripMetrics.collapsedHeight : DeviceStripMetrics.height;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF121218),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: widget.track == null
          ? SizedBox(
              height: stripHeight,
              child: Center(
                child: Text(
                  'Select a track to show devices',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white38),
                ),
              ),
            )
          : _trackDevices(context, widget.track!, collapsed, stripHeight),
    );
  }

  Widget _trackDevices(
    BuildContext context,
    TrackSnapshot track,
    bool collapsed,
    double stripHeight,
  ) {
    final sampler = track.samplerDevice;
    if (sampler != null) {
      if (collapsed) {
        return SizedBox(
          height: stripHeight,
          child: SamplerDeviceStripCollapsed(
            device: sampler,
            sample: _sampleForDevice(sampler),
            activeTab: _samplerTab,
            onExpand: () => setState(() => _expanded = true),
            onOpenFullscreen: () => widget.onOpenSamplerEditor(track, sampler),
          ),
        );
      }

      return DeviceStripViewport(
        designHeight: DeviceStripMetrics.height,
        child: SamplerDeviceStrip(
          trackName: track.name,
          device: sampler,
          sample: _sampleForDevice(sampler),
          onParameterChanged: (parameterId, value) =>
              widget.onSamplerParameterChanged(sampler.id, parameterId, value),
          onOpenFullscreen: () => widget.onOpenSamplerEditor(track, sampler),
          onTabChanged: (tab) => setState(() => _samplerTab = tab),
          onCollapse: _shouldStartCollapsed(context)
              ? () => setState(() => _expanded = false)
              : null,
        ),
      );
    }

    final oscillator = track.oscillatorDevice;
    if (oscillator == null) {
      return SizedBox(
        height: stripHeight,
        child: Center(
          child: Text(
            'No instrument on ${track.name}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54),
          ),
        ),
      );
    }

    if (collapsed) {
      return SizedBox(
        height: stripHeight,
        child: OscillatorDeviceStripCollapsed(
          trackName: track.name,
          frequencyHz: oscillator.frequencyHz,
          onExpand: () => setState(() => _expanded = true),
        ),
      );
    }

    return DeviceStripViewport(
      designWidth: 360,
      designHeight: DeviceStripMetrics.height,
      child: OscillatorDevicePanel(
        trackName: track.name,
        frequencyHz: oscillator.frequencyHz,
        onFrequencyChanged: (value) => widget.onFrequencyChanged(oscillator.id, value),
        onCollapse: _shouldStartCollapsed(context)
            ? () => setState(() => _expanded = false)
            : null,
      ),
    );
  }
}
