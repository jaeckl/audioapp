import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'device_chain_minimap.dart';
import 'device_chain_row.dart';
import 'device_strip_slot.dart';
import 'sampler_device_panel.dart';

/// Fullscreen horizontally scrollable device chain for the selected track.
class DeviceChainScreen extends StatefulWidget {
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
    this.onBypassToggle,
    this.onOpenLibrary,
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
  final void Function(String deviceId, bool bypassed)? onBypassToggle;
  final void Function(DeviceSnapshot device)? onOpenLibrary;

  @override
  State<DeviceChainScreen> createState() => _DeviceChainScreenState();
}

class _DeviceChainScreenState extends State<DeviceChainScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                      onOpenLibrary: widget.onOpenLibrary,
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
          ],
        ),
      ),
    );
  }
}
