import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/param_descriptor.dart';
import '../../bridge/project_snapshot.dart';
import 'device_chain_row.dart';
import 'device_chain_screen.dart';
import 'device_picker_sheet.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';

class DeviceStrip extends StatefulWidget {
  const DeviceStrip({
    super.key,
    required this.snapshot,
    required this.track,
    required this.samples,
    required this.playing,
    this.playheadBeatListenable,
    this.playheadBeats = 0,
    required this.onSamplerParameterChanged,
    this.onDeviceStringParameterChanged,
    required this.onAssignSamplerSample,
    required this.onOpenSamplerEditor,
    required this.onPreviewSample,
    this.onPreviewSampler,
    required this.onImportSamples,
    required this.onFrequencyChanged,
    required this.onAddDevice,
    required this.onBypassToggle,
    required this.onRemoveDevice,
    required     this.onOpenDeviceLibrary,
    this.onModulationBridgeCall,
    this.automationLinkClipId,
    this.onAutomationParamSelected,
    this.onAutomateParameter,
    this.onGetParamDescriptors,
  });

  final ProjectSnapshot snapshot;
  final TrackSnapshot? track;
  final List<SampleLibraryEntrySnapshot> samples;
  final bool playing;
  final ValueListenable<double>? playheadBeatListenable;
  final double playheadBeats;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(String deviceId, String parameterId, String value)?
      onDeviceStringParameterChanged;
  final void Function(String deviceId, String sampleId) onAssignSamplerSample;
  final void Function(TrackSnapshot track, DeviceSnapshot device) onOpenSamplerEditor;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewSample;
  final ValueChanged<int>? onPreviewSampler;
  final Future<List<SampleLibraryEntrySnapshot>> Function() onImportSamples;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;
  final Future<void> Function(String trackId, String deviceType, int insertIndex)
      onAddDevice;
  final void Function(String deviceId, bool bypassed) onBypassToggle;
  final Future<void> Function(TrackSnapshot track, DeviceSnapshot device) onRemoveDevice;
  final void Function(DeviceSnapshot device) onOpenDeviceLibrary;
  final Future<ProjectSnapshot> Function(String method, Map<String, dynamic> args)?
      onModulationBridgeCall;
  final String? automationLinkClipId;
  final Future<bool> Function(String deviceId, String paramId)? onAutomationParamSelected;
  final void Function(String deviceId, String paramId)? onAutomateParameter;

  /// Optional: fetch param descriptors for the generic fallback editor.
  final Future<List<DeviceParamDescriptor>> Function(String deviceType)?
      onGetParamDescriptors;

  @override
  State<DeviceStrip> createState() => _DeviceStripState();
}

class _DeviceStripState extends State<DeviceStrip> {
  bool _expanded = false;
  final Map<String, SamplerDeviceTab> _samplerTabs = {};
  final Map<String, SubtractiveDeviceTab> _synthTabs = {};

  bool _shouldStartCollapsed(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.height < 720 || size.width < 400;
  }

  SamplerDeviceTab _samplerTabFor(String deviceId) =>
      _samplerTabs[deviceId] ?? SamplerDeviceTab.wave;

  void _setSamplerTab(String deviceId, SamplerDeviceTab tab) {
    setState(() => _samplerTabs[deviceId] = tab);
  }

  SubtractiveDeviceTab _synthTabFor(String deviceId) =>
      _synthTabs[deviceId] ?? SubtractiveDeviceTab.osc;

  void _setSynthTab(String deviceId, SubtractiveDeviceTab tab) {
    setState(() => _synthTabs[deviceId] = tab);
  }

  Future<void> _insertDevice(TrackSnapshot track, int insertIndex) async {
    final deviceType = await showDevicePickerSheet(context);
    if (deviceType == null || !mounted) return;
    await widget.onAddDevice(track.id, deviceType, insertIndex);
  }

  Future<void> _openDeviceChain(TrackSnapshot track) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => DeviceChainScreen(
          snapshot: widget.snapshot,
          track: track,
          samples: widget.samples,
          playing: widget.playing,
          samplerTabFor: _samplerTabFor,
          synthTabFor: _synthTabFor,
          onSamplerParameterChanged: widget.onSamplerParameterChanged,
          onDeviceStringParameterChanged: widget.onDeviceStringParameterChanged,
          onOpenSamplerEditor: widget.onOpenSamplerEditor,
          onFrequencyChanged: widget.onFrequencyChanged,
          onInsertDevice: (insertIndex) => _insertDevice(track, insertIndex),
          onSamplerTabChanged: _setSamplerTab,
          onSynthTabChanged: _setSynthTab,
          onBypassToggle: widget.onBypassToggle,
          onDeleteDevice: (device) => widget.onRemoveDevice(track, device),
          onPreviewAudio: widget.onPreviewSample,
          onAssignSamplerSample: widget.onAssignSamplerSample,
          onImportAudio: () async {
            await widget.onImportSamples();
          },
          onModulationBridgeCall: widget.onModulationBridgeCall,
          automationLinkClipId: widget.automationLinkClipId,
          onAutomationParamSelected: widget.onAutomationParamSelected,
          onAutomateParameter: widget.onAutomateParameter,
          onGetParamDescriptors: widget.onGetParamDescriptors,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = !_expanded && _shouldStartCollapsed(context);
    final stripHeight =
        collapsed ? DeviceStripMetrics.collapsedHeight : DeviceStripMetrics.height;
    final track = widget.track;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF121218),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: track == null
          ? SizedBox(
              height: stripHeight,
              child: Center(
                child: Text(
                  'Select a track to show devices',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white38),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DeviceStripHeader(
                  track: track,
                  deviceCount: track.visibleDevices.length,
                  collapsed: collapsed,
                  showCollapse: _shouldStartCollapsed(context),
                  onOpenFullscreen: () => _openDeviceChain(track),
                  onExpand: collapsed ? () => setState(() => _expanded = true) : null,
                  onCollapse: !collapsed && _shouldStartCollapsed(context)
                      ? () => setState(() => _expanded = false)
                      : null,
                ),
                DeviceChainRow(
                  track: track,
                  routingSnapshot: widget.snapshot,
                  samples: widget.samples,
                  playing: widget.playing,
                  bpm: widget.snapshot.bpm,
                  playheadBeat: widget.playheadBeats,
                  playheadBeatListenable: widget.playheadBeatListenable,
                  lfos: widget.snapshot.lfos,
                  modEdges: widget.snapshot.modEdges,
                  density: collapsed
                      ? DeviceStripSlotDensity.collapsed
                      : DeviceStripSlotDensity.strip,
                  samplerTabFor: _samplerTabFor,
                  synthTabFor: _synthTabFor,
                  onSamplerParameterChanged: widget.onSamplerParameterChanged,
                  onDeviceStringParameterChanged: widget.onDeviceStringParameterChanged,
                  onOpenSamplerEditor: widget.onOpenSamplerEditor,
                  onFrequencyChanged: widget.onFrequencyChanged,
                  onInsertDevice: (insertIndex) => _insertDevice(track, insertIndex),
                  onSamplerTabChanged: _setSamplerTab,
                  onSynthTabChanged: _setSynthTab,
                  onBypassToggle: widget.onBypassToggle,
                  onDeleteDevice: (device) => widget.onRemoveDevice(track, device),
                  onOpenLibrary: widget.onOpenDeviceLibrary,
                  onPreviewSample: widget.onPreviewSample,
                  onPreviewSampler: widget.onPreviewSampler,
                  onModulationBridgeCall: widget.onModulationBridgeCall,
                  automationLinkActive: widget.automationLinkClipId != null,
                  automationLinkClipId: widget.automationLinkClipId,
                  projectAutomationClips: widget.snapshot.allAutomationClips.toList(),
                  onAutomationParamSelected: widget.onAutomationParamSelected,
                  onAutomateParameter: widget.onAutomateParameter,
                  onGetParamDescriptors: widget.onGetParamDescriptors,
                ),
              ],
            ),
    );
  }
}

class _DeviceStripHeader extends StatelessWidget {
  const _DeviceStripHeader({
    required this.track,
    required this.deviceCount,
    required this.onOpenFullscreen,
    this.collapsed = false,
    this.showCollapse = false,
    this.onExpand,
    this.onCollapse,
  });

  final TrackSnapshot track;
  final int deviceCount;
  final VoidCallback onOpenFullscreen;
  final bool collapsed;
  final bool showCollapse;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 6, 4, collapsed ? 0 : 2),
      child: Row(
        children: [
          Text(
            'DEVICES',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFE8A54B),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${track.name} · $deviceCount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70),
            ),
          ),
          if (collapsed && onExpand != null)
            IconButton(
              tooltip: 'Expand device strip',
              visualDensity: VisualDensity.compact,
              onPressed: onExpand,
              icon: const Icon(Icons.unfold_more, size: 20, color: Colors.white54),
            ),
          if (!collapsed && showCollapse && onCollapse != null)
            IconButton(
              tooltip: 'Collapse device strip',
              visualDensity: VisualDensity.compact,
              onPressed: onCollapse,
              icon: const Icon(Icons.unfold_less, size: 20, color: Colors.white54),
            ),
          IconButton(
            tooltip: 'Open device chain',
            visualDensity: VisualDensity.compact,
            onPressed: onOpenFullscreen,
            icon: const Icon(Icons.open_in_full, size: 20, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
