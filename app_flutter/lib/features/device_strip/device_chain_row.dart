import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/param_descriptor.dart';
import '../../bridge/live_meters_dto.dart';
import '../../bridge/project_snapshot.dart';
import 'device_chain_separator.dart';
import 'device_strip_device_kind.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';
import 'device_strip_theme.dart';
import 'device_picker_sheet.dart';
import 'device_insert_slot.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';
import 'routing_device_panel.dart';

/// Horizontally scrollable Bitwig/Ableton-style device chain row.
class DeviceChainRow extends StatelessWidget {
  const DeviceChainRow({
    super.key,
    required this.track,
    this.routingSnapshot,
    required this.samples,
    required this.playing,
    required this.bpm,
    this.playheadBeat = 0,
    this.playheadBeatListenable,
    this.liveMetersListenable,
    required this.density,
    required this.onSamplerParameterChanged,
    this.onDeviceStringParameterChanged,
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
    this.onOpenDrumPadLibrary,
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
    this.onGetParamDescriptors,
    this.drumSelectedNoteFor,
    this.drumBankStartFor,
    this.drumChainExpandedFor,
    this.onDrumPadSelected,
    this.onDrumBankChanged,
    this.onDrumChainToggle,
  });

  final TrackSnapshot track;
  final ProjectSnapshot? routingSnapshot;
  final List<SampleLibraryEntrySnapshot> samples;
  final bool playing;
  final int bpm;
  final double playheadBeat;
  final ValueListenable<double>? playheadBeatListenable;
  final ValueListenable<Map<String, DeviceMeterReading>>? liveMetersListenable;
  final DeviceStripSlotDensity density;
  final void Function(String deviceId, String parameterId, double value)
      onSamplerParameterChanged;
  final void Function(String deviceId, String parameterId, String value)?
      onDeviceStringParameterChanged;
  final void Function(TrackSnapshot track, DeviceSnapshot device)
      onOpenSamplerEditor;
  final void Function(String deviceId, double frequencyHz) onFrequencyChanged;
  final void Function(int insertIndex) onInsertDevice;
  final void Function(String deviceId, SamplerDeviceTab tab)?
      onSamplerTabChanged;
  final void Function(String deviceId, SubtractiveDeviceTab tab)?
      onSynthTabChanged;
  final VoidCallback? onCollapse;
  final SamplerDeviceTab Function(String deviceId)? samplerTabFor;
  final SubtractiveDeviceTab Function(String deviceId)? synthTabFor;
  final ScrollController? scrollController;
  final void Function(String deviceId, bool bypassed)? onBypassToggle;
  final void Function(DeviceSnapshot device)? onDeleteDevice;
  final void Function(DeviceSnapshot device)? onOpenLibrary;
  final void Function(DrumMachineDeviceSnapshot device, int note)?
      onOpenDrumPadLibrary;
  final ValueChanged<SampleLibraryEntrySnapshot>? onPreviewSample;
  final ValueChanged<int>? onPreviewSampler;
  final List<LfoSnapshot> lfos;
  final List<ModulationEdgeSnapshot> modEdges;
  final Future<ProjectSnapshot> Function(
      String method, Map<String, dynamic> args)? onModulationBridgeCall;
  final bool automationLinkActive;
  final String? automationLinkClipId;
  final List<AutomationClipSnapshot> projectAutomationClips;
  final Future<bool> Function(String deviceId, String paramId)?
      onAutomationParamSelected;
  final void Function(String deviceId, String paramId)? onAutomateParameter;

  /// Optional: fetch param descriptors for the generic fallback editor.
  final Future<List<DeviceParamDescriptor>> Function(String deviceType)?
      onGetParamDescriptors;
  final int Function(String deviceId)? drumSelectedNoteFor;
  final int Function(String deviceId)? drumBankStartFor;
  final bool Function(String deviceId)? drumChainExpandedFor;
  final void Function(String deviceId, int note)? onDrumPadSelected;
  final void Function(String deviceId, int start)? onDrumBankChanged;
  final ValueChanged<String>? onDrumChainToggle;

  double get _rowHeight => switch (density) {
        DeviceStripSlotDensity.fullscreen =>
          DeviceStripMetrics.fullscreenHeight,
        DeviceStripSlotDensity.collapsed => DeviceStripMetrics.collapsedHeight,
        DeviceStripSlotDensity.strip => DeviceStripMetrics.height,
      };

  SampleLibraryEntrySnapshot? _sampleFor(DeviceSnapshot device) {
    if (device is SamplerDeviceSnapshot) {
      if (device.sampleId.isEmpty) return null;
      for (final sample in samples) {
        if (sample.id == device.sampleId) return sample;
      }
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
                  routingSources: devices[i] is RoutingDeviceSnapshot &&
                          routingSnapshot != null
                      ? buildRoutingSourceOptions(routingSnapshot!, track,
                          devices[i] as RoutingDeviceSnapshot)
                      : const [],
                  device: devices[i],
                  sample: _sampleFor(devices[i]),
                  bpm: bpm,
                  playheadBeat: playheadBeat,
                  playheadBeatListenable: playheadBeatListenable,
                  liveMetersListenable: liveMetersListenable,
                  playing: playing,
                  density: density,
                  samplerTab: samplerTabFor?.call(devices[i].id) ??
                      SamplerDeviceTab.wave,
                  synthTab: synthTabFor?.call(devices[i].id) ??
                      SubtractiveDeviceTab.osc,
                  onSamplerParameterChanged: (parameterId, value) =>
                      onSamplerParameterChanged(
                          devices[i].id, parameterId, value),
                  onDeviceParameterChanged: (parameterId, value) =>
                      onSamplerParameterChanged(
                          devices[i].id, parameterId, value),
                  onDeviceStringParameterChanged: (parameterId, value) =>
                      onDeviceStringParameterChanged?.call(
                          devices[i].id, parameterId, value),
                  onOpenSamplerEditor: () =>
                      onOpenSamplerEditor(track, devices[i]),
                  onFrequencyChanged: (value) =>
                      onFrequencyChanged(devices[i].id, value),
                  onSamplerTabChanged: onSamplerTabChanged == null
                      ? null
                      : (tab) => onSamplerTabChanged!(devices[i].id, tab),
                  onSynthTabChanged: onSynthTabChanged == null
                      ? null
                      : (tab) => onSynthTabChanged!(devices[i].id, tab),
                  onCollapse: density == DeviceStripSlotDensity.strip
                      ? onCollapse
                      : null,
                  onBypassToggle: onBypassToggle == null
                      ? null
                      : () =>
                          onBypassToggle!(devices[i].id, !devices[i].bypassed),
                  onDeleteRequest: onDeleteDevice == null
                      ? null
                      : () => onDeleteDevice!(devices[i]),
                  onOpenLibrary: onOpenLibrary == null
                      ? null
                      : () => onOpenLibrary!(devices[i]),
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
                  onGetParamDescriptors: onGetParamDescriptors,
                  drumSelectedNote:
                      drumSelectedNoteFor?.call(devices[i].id) ?? 36,
                  drumBankStart: drumBankStartFor?.call(devices[i].id) ?? 36,
                  drumChainExpanded:
                      drumChainExpandedFor?.call(devices[i].id) ?? true,
                  onDrumPadSelected: (note) =>
                      onDrumPadSelected?.call(devices[i].id, note),
                  onDrumBankChanged: (start) =>
                      onDrumBankChanged?.call(devices[i].id, start),
                  onDrumChainToggle: () =>
                      onDrumChainToggle?.call(devices[i].id),
                  onDrumTriggerNote: (note) => onPreviewSampler?.call(note),
                  onEmptyDrumPadTap: (note) {
                    onDrumPadSelected?.call(devices[i].id, note);
                    onOpenDrumPadLibrary?.call(
                        devices[i] as DrumMachineDeviceSnapshot, note);
                  },
                ),
                if (devices[i] is DrumMachineDeviceSnapshot &&
                    (drumChainExpandedFor?.call(devices[i].id) ?? true))
                  _virtualPadChain(
                      context, devices[i] as DrumMachineDeviceSnapshot),
                DeviceChainSeparator(
                  active: playing,
                  gain: devices[i].chainVuGain,
                  onInsert: track.canInsertDevices
                      ? () => onInsertDevice(deviceInsertIndexAfter(track, i))
                      : null,
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _virtualPadChain(
      BuildContext context, DrumMachineDeviceSnapshot machine) {
    final note = drumSelectedNoteFor?.call(machine.id) ?? 36;
    final pad = machine.padForNote(note);
    final accent = DeviceStripTheme.accentForDeviceType('drum_machine');
    Future<void> addDevice() async {
      final type = await showDevicePickerSheet(context);
      if (type == null || type == 'drum_machine') return;
      await onModulationBridgeCall?.call('addDeviceToDrumPad', {
        'drumMachineId': machine.id,
        'note': note,
        'deviceType': type,
      });
    }

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: CustomPaint(
        painter: _VirtualChainBracketPainter(accent),
        child: ColoredBox(
          color: accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
            child: Row(children: [
              RotatedBox(
                quarterTurns: 3,
                child: Text('PAD $note',
                    style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              ),
              const SizedBox(width: 7),
              if (pad.devices.isEmpty)
                SizedBox(
                  width: DeviceStripMetrics.separatorWidth,
                  child: Center(
                      child: DeviceInsertSlot(
                    accentColor: accent,
                    onPressed: addDevice,
                  )),
                )
              else
                for (final child in pad.devices) ...[
                  DeviceStripSlot(
                    track: track,
                    routingSources: const [],
                    device: child,
                    sample: _sampleFor(child),
                    bpm: bpm,
                    playheadBeat: playheadBeat,
                    playheadBeatListenable: playheadBeatListenable,
                    liveMetersListenable: liveMetersListenable,
                    playing: playing,
                    density: density,
                    samplerTab:
                        samplerTabFor?.call(child.id) ?? SamplerDeviceTab.wave,
                    synthTab:
                        synthTabFor?.call(child.id) ?? SubtractiveDeviceTab.osc,
                    onSamplerParameterChanged: (id, value) =>
                        onSamplerParameterChanged(child.id, id, value),
                    onDeviceParameterChanged: (id, value) =>
                        onSamplerParameterChanged(child.id, id, value),
                    onDeviceStringParameterChanged: (id, value) =>
                        onDeviceStringParameterChanged?.call(
                            child.id, id, value),
                    onOpenSamplerEditor: () =>
                        onOpenSamplerEditor(track, child),
                    onFrequencyChanged: (value) =>
                        onFrequencyChanged(child.id, value),
                    onBypassToggle: onBypassToggle == null
                        ? null
                        : () => onBypassToggle!(child.id, !child.bypassed),
                    onDeleteRequest: () => onModulationBridgeCall
                        ?.call('removeDeviceFromDrumPad', {
                      'drumMachineId': machine.id,
                      'note': note,
                      'deviceId': child.id,
                    }),
                    onOpenLibrary: onOpenLibrary == null
                        ? null
                        : () => onOpenLibrary!(child),
                    onPreviewSample: onPreviewSample,
                    onPreviewSampler: onPreviewSampler,
                    lfos: lfos,
                    modEdges: modEdges,
                    onModulationBridgeCall: onModulationBridgeCall,
                    onGetParamDescriptors: onGetParamDescriptors,
                  ),
                  const SizedBox(width: 5),
                ],
              if (pad.devices.isNotEmpty && pad.devices.length < 4)
                SizedBox(
                  width: DeviceStripMetrics.separatorWidth,
                  child: Center(
                      child: DeviceInsertSlot(
                    accentColor: accent,
                    onPressed: addDevice,
                  )),
                ),
            ]),
          ),
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
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Colors.white38),
              ),
            ),
          ),
          DeviceChainSeparator(
            active: playing,
            gain: 0.35,
            onInsert: track.canInsertDevices ? () => onInsertDevice(0) : null,
          ),
        ],
      ),
    );
  }
}

class _VirtualChainBracketPainter extends CustomPainter {
  const _VirtualChainBracketPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const tick = 9.0;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset.zero, const Offset(0, tick), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, tick), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - tick), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - tick), paint);
  }

  @override
  bool shouldRepaint(covariant _VirtualChainBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}
