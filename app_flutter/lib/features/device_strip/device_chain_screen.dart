import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import '../content_library/library_category.dart';
import '../content_library/library_fly_in_panel.dart';
import 'device_chain_minimap.dart';
import 'device_chain_row.dart';
import 'device_strip_slot.dart';
import 'sampler_device_panel.dart';

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
    this.onBypassToggle,
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
  final void Function(String deviceId, bool bypassed)? onBypassToggle;

  @override
  State<DeviceChainScreen> createState() => _DeviceChainScreenState();
}

class _DeviceChainScreenState extends State<DeviceChainScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<LibraryFlyInPanelState> _libraryPanelKey = GlobalKey();
  DeviceSnapshot? _libraryDevice;

  @override
  void dispose() {
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
      widget.onAssignSamplerSample(device.id, sample.id);
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
                      track: widget.track,
                      samples: widget.samples,
                      playing: widget.playing,
                      density: density,
                      scrollController: _scrollController,
                      samplerTabFor: widget.samplerTabFor,
                      onSamplerParameterChanged: widget.onSamplerParameterChanged,
                      onOpenSamplerEditor: widget.onOpenSamplerEditor,
                      onFrequencyChanged: widget.onFrequencyChanged,
                      onInsertDevice: widget.onInsertDevice,
                      onSamplerTabChanged: widget.onSamplerTabChanged,
                      onBypassToggle: widget.onBypassToggle,
                      onOpenLibrary: _openLibrary,
                    ),
                  ),
                ),
                DeviceChainMinimap(
                  track: widget.track,
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
