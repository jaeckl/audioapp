import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../bridge/param_descriptor.dart';
import '../../bridge/live_meters_dto.dart';
import '../../bridge/project_snapshot.dart';
import '../content_library/library_filter.dart';
import '../clip_drag/sample_clip_drag_data.dart';
import 'device_chain_separator.dart';
import 'device_strip_device_kind.dart';
import 'device_strip_metrics.dart';
import 'device_strip_slot.dart';
import 'device_strip_theme.dart';
import 'device_picker_sheet.dart';
import 'device_insert_slot.dart';
import 'meter_subscription.dart';
import 'live_automation_value.dart';
import 'sampler_device_panel.dart';
import 'subtractive_synth_device_panel.dart';
import 'routing_device_panel.dart';

/// Horizontally scrollable Bitwig/Ableton-style device chain row.
class DeviceChainRow extends StatefulWidget {
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
    this.onMeterSubscriptionsChanged,
    this.onCreateSamplerFromDroppedSample,
    this.onAssignDroppedSampleToDevice,
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
  final void Function(DeviceSnapshot device, LibraryFilter filter)? onOpenLibrary;
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
  final ValueChanged<List<String>>? onMeterSubscriptionsChanged;
  final Future<void> Function(SampleClipDragData sample, int insertIndex)?
      onCreateSamplerFromDroppedSample;
  final Future<void> Function(DeviceSnapshot device, SampleClipDragData sample)?
      onAssignDroppedSampleToDevice;

  @override
  State<DeviceChainRow> createState() => _DeviceChainRowState();
}

class _DeviceChainRowState extends State<DeviceChainRow> {
  ScrollController? _ownedScrollController;
  List<String> _lastReported = const [];

  ScrollController get _scrollController =>
      widget.scrollController ?? _ownedScrollController!;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController()
        ..addListener(_scheduleMeterReport);
    } else {
      widget.scrollController!.addListener(_scheduleMeterReport);
    }
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _reportMeterSubscriptions());
  }

  @override
  void dispose() {
    _ownedScrollController?.dispose();
    widget.scrollController?.removeListener(_scheduleMeterReport);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DeviceChainRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track != widget.track ||
        oldWidget.density != widget.density ||
        oldWidget.onMeterSubscriptionsChanged !=
            widget.onMeterSubscriptionsChanged) {
      _scheduleMeterReport();
    }
  }

  void _scheduleMeterReport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reportMeterSubscriptions();
    });
  }

  void _reportMeterSubscriptions() {
    final callback = widget.onMeterSubscriptionsChanged;
    if (callback == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final ids = MeterSubscription.visibleMeterDeviceIds(
      track: widget.track,
      density: widget.density,
      scrollController: _scrollController,
      viewportWidth: box.size.width,
    );
    if (listEquals(ids, _lastReported)) return;
    _lastReported = ids;
    callback(ids);
  }

  double get _rowHeight => switch (widget.density) {
        DeviceStripSlotDensity.fullscreen =>
          DeviceStripMetrics.fullscreenHeight,
        DeviceStripSlotDensity.collapsed => DeviceStripMetrics.collapsedHeight,
        DeviceStripSlotDensity.strip => DeviceStripMetrics.height,
      };

  SampleLibraryEntrySnapshot? _sampleFor(DeviceSnapshot device) {
    final sampleId = switch (device) {
      SamplerDeviceSnapshot d => d.sampleId,
      GranularDeviceSnapshot d => d.sampleId,
      _ => '',
    };
    if (sampleId.isNotEmpty) {
      for (final sample in widget.samples) {
        if (sample.id == sampleId) return sample;
      }
    }
    return null;
  }

  bool _canAcceptSampleDrop(DeviceSnapshot device) =>
      device is SamplerDeviceSnapshot || device is GranularDeviceSnapshot;

  Widget _sampleDropTarget({
    required Widget child,
    required bool enabled,
    required Future<void> Function(SampleClipDragData sample) onAccept,
  }) {
    if (!enabled) return child;
    return DragTarget<SampleClipDragData>(
      onWillAcceptWithDetails: (details) => details.data.sampleId.isNotEmpty,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, _) {
        final active = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: active
              ? BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(DeviceStripTheme.cardRadius + 4),
                  border: Border.all(
                    color: DeviceStripTheme.samplerAccent,
                    width: 2,
                  ),
                )
              : null,
          child: child,
        );
      },
    );
  }

  Widget _automationAwareDevice(
    DeviceSnapshot device,
    Widget Function(DeviceSnapshot displayDevice) builder,
  ) {
    DeviceSnapshot at(double beat) => applyLiveAutomation(
          device,
          widget.projectAutomationClips,
          beat,
        );
    final playhead = widget.playheadBeatListenable;
    if (playhead == null) return builder(at(widget.playheadBeat));
    return ValueListenableBuilder<double>(
      valueListenable: playhead,
      builder: (_, beat, __) => builder(at(beat)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = widget.track.visibleDevices.toList();

    return SizedBox(
      height: _rowHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
        child: ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: widget.density == DeviceStripSlotDensity.collapsed
              ? const EdgeInsets.fromLTRB(
                  8,
                  DeviceStripTheme.collapsedChainTopPadding,
                  8,
                  DeviceStripTheme.collapsedChainBottomPadding,
                )
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          children: [
            if (devices.isEmpty)
              _sampleDropTarget(
                enabled: widget.track.canInsertDevices &&
                    widget.onCreateSamplerFromDroppedSample != null,
                onAccept: (sample) =>
                    widget.onCreateSamplerFromDroppedSample!(sample, 0),
                child: _leadingInsert(context),
              )
            else
              for (var i = 0; i < devices.length; i++) ...[
                _automationAwareDevice(
                  devices[i],
                  (displayDevice) => _sampleDropTarget(
                    enabled: _canAcceptSampleDrop(devices[i]) &&
                        widget.onAssignDroppedSampleToDevice != null,
                    onAccept: (sample) => widget.onAssignDroppedSampleToDevice!(
                        devices[i], sample),
                    child: DeviceStripSlot(
                      track: widget.track,
                      routingSources: devices[i] is RoutingDeviceSnapshot &&
                              widget.routingSnapshot != null
                          ? buildRoutingSourceOptions(widget.routingSnapshot!,
                              widget.track, devices[i] as RoutingDeviceSnapshot)
                          : const [],
                      device: displayDevice,
                      sample: _sampleFor(devices[i]),
                      bpm: widget.bpm,
                      playheadBeat: widget.playheadBeat,
                      playheadBeatListenable: widget.playheadBeatListenable,
                      liveMetersListenable: widget.liveMetersListenable,
                      playing: widget.playing,
                      density: widget.density,
                      samplerTab: widget.samplerTabFor?.call(devices[i].id) ??
                          SamplerDeviceTab.wave,
                      synthTab: widget.synthTabFor?.call(devices[i].id) ??
                          SubtractiveDeviceTab.osc,
                      onSamplerParameterChanged: (parameterId, value) =>
                          widget.onSamplerParameterChanged(
                              devices[i].id, parameterId, value),
                      onDeviceParameterChanged: (parameterId, value) =>
                          widget.onSamplerParameterChanged(
                              devices[i].id, parameterId, value),
                      onDeviceStringParameterChanged: (parameterId, value) =>
                          widget.onDeviceStringParameterChanged
                              ?.call(devices[i].id, parameterId, value),
                      onOpenSamplerEditor: () =>
                          widget.onOpenSamplerEditor(widget.track, devices[i]),
                      onFrequencyChanged: (value) =>
                          widget.onFrequencyChanged(devices[i].id, value),
                      onSamplerTabChanged: widget.onSamplerTabChanged == null
                          ? null
                          : (tab) =>
                              widget.onSamplerTabChanged!(devices[i].id, tab),
                      onSynthTabChanged: widget.onSynthTabChanged == null
                          ? null
                          : (tab) =>
                              widget.onSynthTabChanged!(devices[i].id, tab),
                      onCollapse: widget.density == DeviceStripSlotDensity.strip
                          ? widget.onCollapse
                          : null,
                      onBypassToggle: widget.onBypassToggle == null
                          ? null
                          : () => widget.onBypassToggle!(
                              devices[i].id, !devices[i].bypassed),
                      onDeleteRequest: widget.onDeleteDevice == null
                          ? null
                          : () => widget.onDeleteDevice!(devices[i]),
                      onOpenLibrary: widget.onOpenLibrary == null
                          ? null
                          : (filter) => widget.onOpenLibrary!(devices[i], filter),
                      onPreviewSample: widget.onPreviewSample,
                      onPreviewSampler: widget.onPreviewSampler,
                      lfos: widget.lfos,
                      modEdges: widget.modEdges,
                      onModulationBridgeCall: widget.onModulationBridgeCall,
                      automationLinkActive: widget.automationLinkActive,
                      automationLinkClipId: widget.automationLinkClipId,
                      projectAutomationClips: widget.projectAutomationClips,
                      onAutomationParamSelected:
                          widget.onAutomationParamSelected,
                      onAutomateParameter: widget.onAutomateParameter,
                      onGetParamDescriptors: widget.onGetParamDescriptors,
                      drumSelectedNote:
                          widget.drumSelectedNoteFor?.call(devices[i].id) ?? 36,
                      drumBankStart:
                          widget.drumBankStartFor?.call(devices[i].id) ?? 36,
                      drumChainExpanded:
                          widget.drumChainExpandedFor?.call(devices[i].id) ??
                              true,
                      onDrumPadSelected: (note) =>
                          widget.onDrumPadSelected?.call(devices[i].id, note),
                      onDrumBankChanged: (start) =>
                          widget.onDrumBankChanged?.call(devices[i].id, start),
                      onDrumChainToggle: () =>
                          widget.onDrumChainToggle?.call(devices[i].id),
                      onDrumTriggerNote: (note) =>
                          widget.onPreviewSampler?.call(note),
                      onEmptyDrumPadTap: (note) {
                        widget.onDrumPadSelected?.call(devices[i].id, note);
                        widget.onOpenDrumPadLibrary?.call(
                            devices[i] as DrumMachineDeviceSnapshot, note);
                      },
                    ),
                  ),
                ),
                if (devices[i] is DrumMachineDeviceSnapshot &&
                    (widget.drumChainExpandedFor?.call(devices[i].id) ?? true))
                  _virtualPadChain(
                      context, devices[i] as DrumMachineDeviceSnapshot),
                if (devices[i] is ChainDeviceSnapshot)
                  _virtualDeviceChain(
                      context, devices[i] as ChainDeviceSnapshot),
                _sampleDropTarget(
                  enabled: widget.track.canInsertDevices &&
                      widget.onCreateSamplerFromDroppedSample != null,
                  onAccept: (sample) =>
                      widget.onCreateSamplerFromDroppedSample!(
                    sample,
                    deviceInsertIndexAfter(widget.track, i),
                  ),
                  child: DeviceChainSeparator(
                    active: widget.playing,
                    gain: devices[i].chainVuGain,
                    onInsert: widget.track.canInsertDevices
                        ? () => widget.onInsertDevice(
                            deviceInsertIndexAfter(widget.track, i))
                        : null,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _virtualDeviceChain(BuildContext context, ChainDeviceSnapshot chain) {
    final accent = DeviceStripTheme.accentForDeviceType('device_chain');
    Future<void> addDevice() async {
      final type = await showDevicePickerSheet(context);
      if (type == null || type == 'device_chain') return;
      await widget.onModulationBridgeCall?.call('addDeviceToChain', {
        'chainId': chain.id,
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
                  child: Text('CHAIN',
                      style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8))),
              const SizedBox(width: 7),
              for (final child in chain.devices) ...[
                _automationAwareDevice(
                    child,
                    (displayChild) => _sampleDropTarget(
                        enabled: _canAcceptSampleDrop(child) &&
                            widget.onAssignDroppedSampleToDevice != null,
                        onAccept: (sample) => widget
                            .onAssignDroppedSampleToDevice!(child, sample),
                        child: DeviceStripSlot(
                          track: widget.track,
                          routingSources: const [],
                          device: displayChild,
                          sample: _sampleFor(child),
                          bpm: widget.bpm,
                          playheadBeat: widget.playheadBeat,
                          playheadBeatListenable: widget.playheadBeatListenable,
                          liveMetersListenable: widget.liveMetersListenable,
                          playing: widget.playing,
                          density: widget.density,
                          samplerTab: widget.samplerTabFor?.call(child.id) ??
                              SamplerDeviceTab.wave,
                          synthTab: widget.synthTabFor?.call(child.id) ??
                              SubtractiveDeviceTab.osc,
                          onSamplerParameterChanged: (id, value) => widget
                              .onSamplerParameterChanged(child.id, id, value),
                          onDeviceParameterChanged: (id, value) => widget
                              .onSamplerParameterChanged(child.id, id, value),
                          onDeviceStringParameterChanged: (id, value) => widget
                              .onDeviceStringParameterChanged
                              ?.call(child.id, id, value),
                          onOpenSamplerEditor: () =>
                              widget.onOpenSamplerEditor(widget.track, child),
                          onFrequencyChanged: (value) =>
                              widget.onFrequencyChanged(child.id, value),
                          onBypassToggle: widget.onBypassToggle == null
                              ? null
                              : () => widget.onBypassToggle!(
                                  child.id, !child.bypassed),
                          onDeleteRequest: () => widget.onModulationBridgeCall
                              ?.call('removeDeviceFromChain',
                                  {'chainId': chain.id, 'deviceId': child.id}),
                          onOpenLibrary: widget.onOpenLibrary == null
                              ? null
                              : (filter) => widget.onOpenLibrary!(child, filter),
                          onPreviewSample: widget.onPreviewSample,
                          onPreviewSampler: widget.onPreviewSampler,
                          lfos: widget.lfos,
                          modEdges: widget.modEdges,
                          onModulationBridgeCall: widget.onModulationBridgeCall,
                          automationLinkActive: widget.automationLinkActive,
                          automationLinkClipId: widget.automationLinkClipId,
                          projectAutomationClips: widget.projectAutomationClips,
                          onAutomationParamSelected:
                              widget.onAutomationParamSelected,
                          onAutomateParameter: widget.onAutomateParameter,
                          onGetParamDescriptors: widget.onGetParamDescriptors,
                        ))),
                const SizedBox(width: 5),
              ],
              if (chain.devices.length < 8)
                SizedBox(
                  width: DeviceStripMetrics.separatorWidth,
                  child: Center(
                      child: DeviceInsertSlot(
                          accentColor: accent, onPressed: addDevice)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _virtualPadChain(
      BuildContext context, DrumMachineDeviceSnapshot machine) {
    final note = widget.drumSelectedNoteFor?.call(machine.id) ?? 36;
    final pad = machine.padForNote(note);
    final accent = DeviceStripTheme.accentForDeviceType('drum_machine');
    Future<void> addDevice() async {
      final type = await showDevicePickerSheet(context);
      if (type == null || type == 'drum_machine') return;
      await widget.onModulationBridgeCall?.call('addDeviceToDrumPad', {
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
                  _automationAwareDevice(
                    child,
                    (displayChild) => _sampleDropTarget(
                      enabled: _canAcceptSampleDrop(child) &&
                          widget.onAssignDroppedSampleToDevice != null,
                      onAccept: (sample) =>
                          widget.onAssignDroppedSampleToDevice!(child, sample),
                      child: DeviceStripSlot(
                        track: widget.track,
                        routingSources: const [],
                        device: displayChild,
                        sample: _sampleFor(child),
                        bpm: widget.bpm,
                        playheadBeat: widget.playheadBeat,
                        playheadBeatListenable: widget.playheadBeatListenable,
                        liveMetersListenable: widget.liveMetersListenable,
                        playing: widget.playing,
                        density: widget.density,
                        samplerTab: widget.samplerTabFor?.call(child.id) ??
                            SamplerDeviceTab.wave,
                        synthTab: widget.synthTabFor?.call(child.id) ??
                            SubtractiveDeviceTab.osc,
                        onSamplerParameterChanged: (id, value) => widget
                            .onSamplerParameterChanged(child.id, id, value),
                        onDeviceParameterChanged: (id, value) => widget
                            .onSamplerParameterChanged(child.id, id, value),
                        onDeviceStringParameterChanged: (id, value) => widget
                            .onDeviceStringParameterChanged
                            ?.call(child.id, id, value),
                        onOpenSamplerEditor: () =>
                            widget.onOpenSamplerEditor(widget.track, child),
                        onFrequencyChanged: (value) =>
                            widget.onFrequencyChanged(child.id, value),
                        onBypassToggle: widget.onBypassToggle == null
                            ? null
                            : () => widget.onBypassToggle!(
                                child.id, !child.bypassed),
                        onDeleteRequest: () => widget.onModulationBridgeCall
                            ?.call('removeDeviceFromDrumPad', {
                          'drumMachineId': machine.id,
                          'note': note,
                          'deviceId': child.id,
                        }),
                        onOpenLibrary: widget.onOpenLibrary == null
                            ? null
                            : (filter) => widget.onOpenLibrary!(child, filter),
                        onPreviewSample: widget.onPreviewSample,
                        onPreviewSampler: widget.onPreviewSampler,
                        lfos: widget.lfos,
                        modEdges: widget.modEdges,
                        onModulationBridgeCall: widget.onModulationBridgeCall,
                        automationLinkActive: widget.automationLinkActive,
                        automationLinkClipId: widget.automationLinkClipId,
                        projectAutomationClips: widget.projectAutomationClips,
                        onAutomationParamSelected:
                            widget.onAutomationParamSelected,
                        onAutomateParameter: widget.onAutomateParameter,
                        onGetParamDescriptors: widget.onGetParamDescriptors,
                      ),
                    ),
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
            active: widget.playing,
            gain: 0.35,
            onInsert: widget.track.canInsertDevices
                ? () => widget.onInsertDevice(0)
                : null,
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
