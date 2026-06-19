import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_chain_separator.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';
import 'device_strip_theme.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';

/// Horizontally scrollable Bitwig/Ableton-style device chain row.
class DeviceChainRow extends StatelessWidget {
  const DeviceChainRow({
    super.key,
    required this.track,
    required this.samples,
    required this.playing,
    required this.bpm,
    this.playheadBeat = 0,
    required this.density,
    required this.onSamplerParameterChanged,
    required this.onOpenSamplerEditor,
    required this.onFrequencyChanged,
    required this.onInsertDevice,
    this.onSamplerTabChanged,
    this.onSynthTabChanged,
    this.onCollapse,
    this.samplerTabFor,
    this.synthTabFor,
    this.scrollController,
    this.onBypassToggle,
    this.onDeleteDevice,
    this.onOpenLibrary,
    this.onPreviewSample,
    this.onPreviewSampler,
    this.lfos = const [],
    this.modEdges = const [],
    this.onModulationBridgeCall,
    this.automationLinkActive = false,
    this.automationLinkClipId,
    this.projectAutomationClips = const [],
    this.onAutomationParamSelected,
    this.onAutomateParameter,
  });

  final TrackSnapshot track;
  final List<SampleLibraryEntrySnapshot> samples;
  final bool playing;
  final int bpm;
  final double playheadBeat;
  final DeviceStripSlotDensity density;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(TrackSnapshot track, DeviceSnapshot device) onOpenSamplerEditor;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;
  final void Function(int insertIndex) onInsertDevice;
  final void Function(String deviceId, SamplerDeviceTab tab)? onSamplerTabChanged;
  final void Function(String deviceId, SubtractiveDeviceTab tab)? onSynthTabChanged;
  final VoidCallback? onCollapse;
  final SamplerDeviceTab Function(String deviceId)? samplerTabFor;
  final SubtractiveDeviceTab Function(String deviceId)? synthTabFor;
  final ScrollController? scrollController;
  final void Function(String deviceId, bool bypassed)? onBypassToggle;
  final void Function(DeviceSnapshot device)? onDeleteDevice;
  final void Function(DeviceSnapshot device)? onOpenLibrary;
  final ValueChanged<SampleLibraryEntrySnapshot>? onPreviewSample;
  final ValueChanged<int>? onPreviewSampler;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final Future<ProjectSnapshot> Function(String method, Map<String, dynamic> args)?
      onModulationBridgeCall;
  final bool automationLinkActive;
  final String? automationLinkClipId;
  final List<AutomationClipSnapshot> projectAutomationClips;
  final Future<bool> Function(String deviceId, String paramId)? onAutomationParamSelected;
  final void Function(String deviceId, String paramId)? onAutomateParameter;

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
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: density == DeviceStripSlotDensity.collapsed
              ? const EdgeInsets.fromLTRB(
                  8,
                  DeviceStripTheme.collapsedChainTopPadding,
                  8,
                  DeviceStripTheme.collapsedChainBottomPadding,
                )
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          children: [
            if (devices.isEmpty)
              _leadingInsert(context)
            else
              for (var i = 0; i < devices.length; i++) ...[
                DeviceStripSlot(
                  track: track,
                  device: devices[i],
                  sample: _sampleFor(devices[i]),
                  bpm: bpm,
                  playheadBeat: playheadBeat,
                  playing: playing,
                  density: density,
                  samplerTab: samplerTabFor?.call(devices[i].id) ?? SamplerDeviceTab.wave,
                  synthTab: synthTabFor?.call(devices[i].id) ?? SubtractiveDeviceTab.osc,
                  onSamplerParameterChanged: (parameterId, value) =>
                      onSamplerParameterChanged(devices[i].id, parameterId, value),
                  onDeviceParameterChanged: (parameterId, value) =>
                      onSamplerParameterChanged(devices[i].id, parameterId, value),
                  onOpenSamplerEditor: () => onOpenSamplerEditor(track, devices[i]),
                  onFrequencyChanged: (value) =>
                      onFrequencyChanged(devices[i].id, value),
                  onSamplerTabChanged: onSamplerTabChanged == null
                      ? null
                      : (tab) => onSamplerTabChanged!(devices[i].id, tab),
                  onSynthTabChanged: onSynthTabChanged == null
                      ? null
                      : (tab) => onSynthTabChanged!(devices[i].id, tab),
                  onCollapse: density == DeviceStripSlotDensity.strip ? onCollapse : null,
                  onBypassToggle: onBypassToggle == null
                      ? null
                      : () => onBypassToggle!(devices[i].id, !devices[i].bypassed),
                  onDeleteRequest: onDeleteDevice == null
                      ? null
                      : () => onDeleteDevice!(devices[i]),
                  onOpenLibrary:
                      onOpenLibrary == null ? null : () => onOpenLibrary!(devices[i]),
                  onPreviewSample: onPreviewSample,
                  onPreviewSampler: onPreviewSampler,
                  lfos: lfos,
                  modEdges: modEdges,
                  onModulationBridgeCall: onModulationBridgeCall,
                  automationLinkActive: automationLinkActive,
                  automationLinkClipId: automationLinkClipId,
                  projectAutomationClips: projectAutomationClips,
                  onAutomationParamSelected: onAutomationParamSelected,
                  onAutomateParameter: onAutomateParameter,
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
