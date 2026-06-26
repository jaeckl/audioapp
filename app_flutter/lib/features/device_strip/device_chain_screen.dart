import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bridge/param_descriptor.dart';
import '../../bridge/project_snapshot.dart';
import '../content_library/library_category.dart';
import '../content_library/library_fly_in_panel.dart';
import 'device_chain_minimap.dart';
import 'device_chain_row.dart';
import 'device_strip_slot.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';

/// Fullscreen horizontally scrollable device chain for the selected track.
class DeviceChainScreen extends StatefulWidget {
  const DeviceChainScreen({
    super.key,
    required this.snapshot,
    required this.track,
    required this.samples,
    required this.playing,
    required this.onSamplerParameterChanged,
    required this.onOpenSamplerEditor,
    required this.onFrequencyChanged,
    required this.onInsertDevice,
    required this.onPreviewAudio,
    required this.onAssignSamplerSample,
    required this.onImportAudio,
    this.onSamplerTabChanged,
    this.samplerTabFor,
    this.onSynthTabChanged,
    this.synthTabFor,
    this.onBypassToggle,
    this.onDeleteDevice,
    this.onModulationBridgeCall,
    this.automationLinkClipId,
    this.onAutomationParamSelected,
    this.onAutomateParameter,
    this.onGetParamDescriptors,
  });

  final ProjectSnapshot snapshot;
  final TrackSnapshot track;
  final List<SampleLibraryEntrySnapshot> samples;
  final bool playing;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(TrackSnapshot track, DeviceSnapshot device) onOpenSamplerEditor;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;
  final void Function(int insertIndex) onInsertDevice;
  final ValueChanged<SampleLibraryEntrySnapshot> onPreviewAudio;
  final void Function(String deviceId, String sampleId) onAssignSamplerSample;
  final Future<void> Function() onImportAudio;
  final void Function(String deviceId, SamplerDeviceTab tab)? onSamplerTabChanged;
  final SamplerDeviceTab Function(String deviceId)? samplerTabFor;
  final void Function(String deviceId, SubtractiveDeviceTab tab)? onSynthTabChanged;
  final SubtractiveDeviceTab Function(String deviceId)? synthTabFor;
  final void Function(String deviceId, bool bypassed)? onBypassToggle;
  final void Function(DeviceSnapshot device)? onDeleteDevice;
  final Future<ProjectSnapshot> Function(String method, Map<String, dynamic> args)?
      onModulationBridgeCall;
  final String? automationLinkClipId;
  final Future<bool> Function(String deviceId, String paramId)? onAutomationParamSelected;
  final void Function(String deviceId, String paramId)? onAutomateParameter;

  /// Optional: fetch param descriptors for the generic fallback editor.
  final Future<List<DeviceParamDescriptor>> Function(String deviceType)?
      onGetParamDescriptors;

  @override
  State<DeviceChainScreen> createState() => _DeviceChainScreenState();
}

class _DeviceChainScreenState extends State<DeviceChainScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<LibraryFlyInPanelState> _libraryPanelKey = GlobalKey();
  DeviceSnapshot? _libraryDevice;
  late TrackSnapshot _track;

  @override
  void initState() {
    super.initState();
    _track = widget.track;
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void didUpdateWidget(covariant DeviceChainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _track = widget.track;
    }
  }

  TrackSnapshot _trackWithDeviceParameter(
    String deviceId,
    String parameterId,
    double value,
  ) {
    return TrackSnapshot(
      id: _track.id,
      name: _track.name,
      devices: _track.devices
          .map((device) => device.id == deviceId
              ? device.withParameter(parameterId, value)
              : device)
          .toList(),
      midiClips: _track.midiClips,
      sampleClips: _track.sampleClips,
      automationClips: _track.automationClips,
    );
  }

  void _onSamplerParameterChanged(String deviceId, String parameterId, double value) {
    setState(() => _track = _trackWithDeviceParameter(deviceId, parameterId, value));
    widget.onSamplerParameterChanged(deviceId, parameterId, value);
  }

  void _onFrequencyChanged(String deviceId, double frequencyHz) {
    setState(() {
      _track = TrackSnapshot(
        id: _track.id,
        name: _track.name,
        devices: _track.devices
            .map((device) => device.id == deviceId && device is OscillatorDeviceSnapshot
                ? device.copyWith(frequencyHz: frequencyHz)
                : device)
            .toList(),
        midiClips: _track.midiClips,
        sampleClips: _track.sampleClips,
      );
    });
    widget.onFrequencyChanged(deviceId, frequencyHz);
  }

  void _onBypassToggle(String deviceId, bool bypassed) {
    setState(() => _track = _trackWithDeviceParameter(deviceId, 'bypass', bypassed ? 1.0 : 0.0));
    widget.onBypassToggle?.call(deviceId, bypassed);
  }

  void _onAssignSamplerSample(String deviceId, String sampleId) {
    setState(() {
      _track = TrackSnapshot(
        id: _track.id,
        name: _track.name,
        devices: _track.devices
            .map((device) =>
                device.id == deviceId && device is SamplerDeviceSnapshot ? device.copyWith(sampleId: sampleId) : device)
            .toList(),
        midiClips: _track.midiClips,
        sampleClips: _track.sampleClips,
      );
    });
    widget.onAssignSamplerSample(deviceId, sampleId);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _scrollController.dispose();
    super.dispose();
  }

  void _openLibrary(DeviceSnapshot device) {
    if (device.type != 'simple_sampler') return;
    setState(() => _libraryDevice = device);
  }

  void _closeLibrary() {
    setState(() => _libraryDevice = null);
  }

  Future<void> _onLibraryInsertAudio(SampleLibraryEntrySnapshot sample) async {
    final device = _libraryDevice;
    if (device != null) {
      _onAssignSamplerSample(device.id, sample.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${sample.name}')),
        );
      }
    }
    await _libraryPanelKey.currentState?.close();
  }

  @override
  Widget build(BuildContext context) {
    const density = DeviceStripSlotDensity.fullscreen;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E14),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: DeviceChainRow(
                      track: _track,
                      samples: widget.samples,
                      playing: widget.playing,
                      bpm: widget.snapshot.bpm,
                      playheadBeat: widget.snapshot.playheadBeats,
                      density: density,
                      scrollController: _scrollController,
                      samplerTabFor: widget.samplerTabFor,
                      synthTabFor: widget.synthTabFor,
                      onSamplerParameterChanged: _onSamplerParameterChanged,
                      onOpenSamplerEditor: widget.onOpenSamplerEditor,
                      onFrequencyChanged: _onFrequencyChanged,
                      onInsertDevice: widget.onInsertDevice,
                      onSamplerTabChanged: widget.onSamplerTabChanged,
                      onSynthTabChanged: widget.onSynthTabChanged,
                      onBypassToggle: widget.onBypassToggle == null ? null : _onBypassToggle,
                      onDeleteDevice: widget.onDeleteDevice,
                      onOpenLibrary: _openLibrary,
                      onPreviewSample: widget.onPreviewAudio,
                      lfos: widget.snapshot.lfos,
                      modEdges: widget.snapshot.modEdges,
                      onModulationBridgeCall: widget.onModulationBridgeCall,
                      automationLinkActive: widget.automationLinkClipId != null,
                      automationLinkClipId: widget.automationLinkClipId,
                      projectAutomationClips: widget.snapshot.allAutomationClips.toList(),
                      onAutomationParamSelected: widget.onAutomationParamSelected,
                      onAutomateParameter: widget.onAutomateParameter,
                      onGetParamDescriptors: widget.onGetParamDescriptors,
                    ),
                  ),
                ),
                DeviceChainMinimap(
                  track: _track,
                  scrollController: _scrollController,
                  density: density,
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white54,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.all(8),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 22),
              ),
            ),
            if (_libraryDevice != null)
              LibraryFlyInPanel(
                key: _libraryPanelKey,
                snapshot: widget.snapshot,
                initialCategory: LibraryCategory.audioClips,
                onClose: _closeLibrary,
                onPreviewAudio: widget.onPreviewAudio,
                onInsertAudio: _onLibraryInsertAudio,
                onImportAudio: widget.onImportAudio,
              ),
          ],
        ),
      ),
    );
  }
}
