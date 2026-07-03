import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../automation/automation_editor_theme.dart';
import '../arrangement/arrangement_loop_region_marker.dart';
import '../arrangement/snap_grid_resolution.dart';
import '../editor/clip_editor_transport.dart';
import '../editor/editor_virtual_playhead.dart';
import '../device_strip/rotary_knob.dart';
import 'editable_waveform.dart';
import 'sample_editor_snap.dart';
import 'sample_editor_snap_sheet.dart';

enum _SampleTool { navigate, trim, fade, slice, process }

enum _SampleMenuAction { loop, warp, reverse, normalize }

enum _SliceAutoMode { transient, even, grid }

enum _SliceTab { auto, edit, map }

enum _FadeCurveKind { linear, quadratic, cubic, smooth }

extension _FadeCurveKindX on _FadeCurveKind {
  double get value => switch (this) {
        _FadeCurveKind.linear => 0.0,
        _FadeCurveKind.quadratic => 0.33,
        _FadeCurveKind.cubic => 0.66,
        _FadeCurveKind.smooth => 1.0,
      };

  static _FadeCurveKind fromValue(double value) {
    var closest = _FadeCurveKind.linear;
    var distance = (value - closest.value).abs();
    for (final kind in _FadeCurveKind.values.skip(1)) {
      final next = (value - kind.value).abs();
      if (next < distance) {
        closest = kind;
        distance = next;
      }
    }
    return closest;
  }
}

class SampleEditorScreen extends StatefulWidget {
  const SampleEditorScreen(
      {super.key,
      required this.bridge,
      required this.clip,
      required this.trackName,
      required this.onSnapshot,
      required this.bpm,
      required this.savedArrangementPlayhead});
  final EngineBridge bridge;
  final SampleClipSnapshot clip;
  final String trackName;
  final Future<void> Function(ProjectSnapshot snapshot) onSnapshot;
  final int bpm;
  final double savedArrangementPlayhead;

  @override
  State<SampleEditorScreen> createState() => _SampleEditorScreenState();
}

class _SampleEditorScreenState extends State<SampleEditorScreen>
    with TickerProviderStateMixin {
  late double start = widget.clip.sourceStart;
  late double end = widget.clip.sourceEnd;
  late double gain = widget.clip.gain;
  late double fadeIn = widget.clip.fadeIn;
  late double fadeOut = widget.clip.fadeOut;
  late double fadeInCurve = widget.clip.fadeInCurve;
  late double fadeOutCurve = widget.clip.fadeOutCurve;
  double pixelsPerBeat = 64;
  double zoomStart = 64;
  bool clipInteracting = false;
  bool pinchInteracting = false;
  _SampleTool tool = _SampleTool.navigate;
  SampleEditSnapSettings editSnap = const SampleEditSnapSettings();
  late bool reversed = widget.clip.reversed;
  late bool loopContent = widget.clip.loopContent;
  late bool warpRepitch = widget.clip.warpRepitch;
  late List<double> sliceMarkers = List.of(widget.clip.sliceMarkers);
  double transientSensitivity = .5;
  double sliceMinGap = .04;
  bool sliceReplaceExisting = true;
  _SliceAutoMode sliceAutoMode = _SliceAutoMode.transient;
  int sliceEvenDivisions = 8;
  SampleEditSnap sliceGridDivision = SampleEditSnap.sixteenth;
  int sliceFirstNote = 36;
  int? selectedSlice;
  int? selectedMarker;
  String? sliceStatus;
  bool saving = false;
  late final ClipEditorTransportController transport;
  Timer? saveDebounce;

  double get _playbackContentLengthBeats => widget.clip.playbackContentLengthBeats(
        sourceStart: start,
        sourceEnd: end,
        warpRepitch: warpRepitch,
      );

  void _syncPreviewTransportSpan() {
    transport.maxClipBeat = _playbackContentLengthBeats;
    if (transport.clipLocalBeat > transport.maxClipBeat) {
      transport.seekClipLocal(transport.maxClipBeat);
    }
  }

  @override
  void initState() {
    super.initState();
    transport = ClipEditorTransportController(
        bridge: widget.bridge,
        clipStartBeat: widget.clip.startBeat,
        savedArrangementPlayhead: widget.savedArrangementPlayhead,
        vsync: this,
        maxClipBeat: widget.clip.playbackContentLengthBeats(
          sourceStart: start,
          sourceEnd: end,
          warpRepitch: warpRepitch,
        ));
    transport.addListener(_transportChanged);
    unawaited(widget.bridge.enterPlayMode());
  }

  void _transportChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    saveDebounce?.cancel();
    transport.removeListener(_transportChanged);
    unawaited(transport.disposePreview());
    super.dispose();
  }

  void _scheduleSave() {
    saveDebounce?.cancel();
    saveDebounce = Timer(const Duration(milliseconds: 180), _save);
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final snapshot = await widget.bridge.setSampleClipProperties(
          clipId: widget.clip.id,
          sourceStart: start,
          sourceEnd: end,
          gain: gain,
          fadeIn: fadeIn,
          fadeOut: fadeOut,
          fadeInCurve: fadeInCurve,
          fadeOutCurve: fadeOutCurve,
          reversed: reversed);
      await widget.onSnapshot(snapshot);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _normalize() {
    final peak = widget.clip.waveformPeaks
        .fold<double>(0, (m, p) => p.abs() > m ? p.abs() : m);
    setState(() => gain = peak <= .0001 ? 1 : (1 / peak).clamp(0.0, 4.0));
    _save();
  }

  Future<void> _audition() async {
    await transport.togglePlay(bpm: widget.bpm);
  }

  Future<void> _toggleLoop() async {
    final next = !loopContent;
    setState(() => loopContent = next);
    await widget.onSnapshot(await widget.bridge
        .setClipLoopContent(clipId: widget.clip.id, loopContent: next));
  }

  Future<void> _toggleWarp() async {
    final next = !warpRepitch;
    setState(() => warpRepitch = next);
    _syncPreviewTransportSpan();
    await widget.onSnapshot(await widget.bridge
        .setSampleClipWarp(clipId: widget.clip.id, warpRepitch: next));
  }

  Future<void> _saveSlices() async {
    sliceMarkers.sort();
    await widget.onSnapshot(await widget.bridge
        .setSampleClipSlices(clipId: widget.clip.id, markers: sliceMarkers));
  }

  List<double> _sanitizeMarkers(Iterable<double> markers) {
    final sorted = markers
        .map((marker) => marker.clamp(.001, .999))
        .toSet()
        .toList()
      ..sort();
    final kept = <double>[];
    for (final marker in sorted) {
      if (kept.isEmpty || marker - kept.last >= sliceMinGap) {
        kept.add(marker);
      }
      if (kept.length >= 31) break;
    }
    return kept;
  }

  void _toggleSlice(double position) {
    position = _snapSource(position);
    final nearest =
        sliceMarkers.indexWhere((marker) => (marker - position).abs() < .025);
    setState(() {
      if (nearest >= 0) {
        sliceMarkers.removeAt(nearest);
        if (selectedMarker == nearest) selectedMarker = null;
      } else if (sliceMarkers.length < 31) {
        sliceMarkers.add(position.clamp(.001, .999));
        selectedMarker = sliceMarkers.length - 1;
      }
      sliceMarkers.sort();
    });
    unawaited(_saveSlices());
  }

  void _selectSliceMarker(int index) {
    if (index < 0 || index >= sliceMarkers.length) return;
    setState(() {
      selectedMarker = index;
      selectedSlice = index;
    });
    unawaited(_auditionSlice(sliceMarkers[index]));
  }

  void _moveSlice(int index, double position) {
    position = _snapSource(position);
    if (index < 0 || index >= sliceMarkers.length) return;
    final minimum = index == 0 ? .005 : sliceMarkers[index - 1] + .005;
    final maximum = index == sliceMarkers.length - 1
        ? .995
        : sliceMarkers[index + 1] - .005;
    setState(() => sliceMarkers[index] = position.clamp(minimum, maximum));
  }

  void _deleteSelectedSliceMarker() {
    final index = selectedMarker;
    if (index == null || index < 0 || index >= sliceMarkers.length) return;
    setState(() {
      sliceMarkers.removeAt(index);
      selectedMarker = null;
      selectedSlice = null;
    });
    unawaited(_saveSlices());
  }

  void _nudgeSelectedSliceMarker(int direction) {
    final index = selectedMarker;
    if (index == null || index < 0 || index >= sliceMarkers.length) return;
    final step = editSnap.snap == SampleEditSnap.off
        ? .01
        : math.max(.001, editSnap.snap.sourceStep);
    final minimum = index == 0 ? .005 : sliceMarkers[index - 1] + .005;
    final maximum = index == sliceMarkers.length - 1
        ? .995
        : sliceMarkers[index + 1] - .005;
    setState(() {
      sliceMarkers[index] =
          (sliceMarkers[index] + step * direction).clamp(minimum, maximum);
    });
    unawaited(_saveSlices());
  }

  void _auditionSelectedSliceMarker() {
    final index = selectedMarker;
    if (index == null || index < 0 || index >= sliceMarkers.length) return;
    unawaited(_auditionSlice(sliceMarkers[index]));
  }

  Future<void> _auditionSlice(double position) async {
    final bounds = <double>[0, ...sliceMarkers, 1];
    var index = 0;
    while (index + 1 < bounds.length - 1 && position >= bounds[index + 1]) {
      index++;
    }
    setState(() => selectedSlice = index);
    final window = math.max(.001, end - start);
    final low = reversed ? 1 - bounds[index + 1] : bounds[index];
    final high = reversed ? 1 - bounds[index] : bounds[index + 1];
    await widget.bridge.previewSampleRegion(
      sampleId: widget.clip.sampleId,
      start: start + low * window,
      end: start + high * window,
      reversed: reversed,
    );
  }

  List<double> _detectTransientMarkers() {
    final peaks = widget.clip.waveformPeaks;
    if (peaks.length < 3) return const [];
    final average =
        peaks.fold<double>(0, (sum, value) => sum + value.abs()) / peaks.length;
    final threshold = average * (1.05 + transientSensitivity * 1.8);
    final found = <double>[];
    var lastForward = -1.0;
    final window = math.max(.001, end - start);
    for (var i = 1; i < peaks.length - 1 && found.length < 16; i++) {
      final value = peaks[i].abs();
      final sourcePosition = i / (peaks.length - 1);
      if (sourcePosition < start || sourcePosition > end) continue;
      final forward = (sourcePosition - start) / window;
      final position = reversed ? 1 - forward : forward;
      if (value > threshold &&
          value >= peaks[i - 1].abs() &&
          value > peaks[i + 1].abs() &&
          forward - lastForward > sliceMinGap) {
        found.add(position);
        lastForward = forward;
      }
    }
    return found;
  }

  List<double> _evenSliceMarkers() {
    final divisions = sliceEvenDivisions.clamp(2, 32);
    return List.generate(divisions - 1, (index) => (index + 1) / divisions);
  }

  List<double> _gridSliceMarkers() {
    final stepBeats = switch (sliceGridDivision) {
      SampleEditSnap.off => .25,
      SampleEditSnap.half => 2.0,
      SampleEditSnap.quarter => 1.0,
      SampleEditSnap.eighth => .5,
      SampleEditSnap.sixteenth => .25,
      SampleEditSnap.thirtySecond => .125,
    };
    final natural = math.max(.001, widget.clip.effectiveNaturalLengthBeats);
    final startBeat = start * natural;
    final endBeat = end * natural;
    final markers = <double>[];
    final window = math.max(.001, end - start);
    final firstBeat = (startBeat / stepBeats).ceil() * stepBeats;
    for (var beat = firstBeat; beat < endBeat - .0001; beat += stepBeats) {
      if (beat <= startBeat + .0001) continue;
      final sourcePosition = (beat / natural).clamp(start, end);
      markers.add(((sourcePosition - start) / window).clamp(.001, .999));
    }
    return markers;
  }

  void _autoSlice() {
    var usedFallback = false;
    var generated = switch (sliceAutoMode) {
      _SliceAutoMode.transient => _detectTransientMarkers(),
      _SliceAutoMode.even => _evenSliceMarkers(),
      _SliceAutoMode.grid => _gridSliceMarkers(),
    };
    if (sliceAutoMode == _SliceAutoMode.transient && generated.length < 2) {
      generated = _evenSliceMarkers();
      usedFallback = true;
    }
    final shouldSnapGenerated =
        sliceAutoMode == _SliceAutoMode.transient &&
        editSnap.snap != SampleEditSnap.off;
    final snapped = !shouldSnapGenerated
        ? generated
        : generated.map(editSnap.snapSource).toList();
    final next = sliceReplaceExisting
        ? _sanitizeMarkers(snapped)
        : _sanitizeMarkers([...sliceMarkers, ...snapped]);
    final cutCount = next.length;
    setState(() {
      sliceMarkers = next;
      tool = _SampleTool.slice;
      selectedMarker = null;
      selectedSlice = null;
      sliceStatus = usedFallback
          ? 'Few transients found. Used even slices.'
          : cutCount == 0
              ? 'No slice markers created.'
              : 'Created $cutCount slice markers.';
    });
    unawaited(_saveSlices());
  }

  void _resetSlices() {
    setState(() {
      sliceMarkers.clear();
      selectedMarker = null;
      selectedSlice = null;
      sliceStatus = 'Slices reset.';
    });
    unawaited(_saveSlices());
  }

  Future<void> _exportSlices() async {
    final snapshot = await widget.bridge.exportSampleClipSlices(
        clipId: widget.clip.id, firstNote: sliceFirstNote);
    await widget.onSnapshot(snapshot);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Created Drum Machine with ${sliceMarkers.length + 1} slices')));
  }

  String get _snapLabel => editSnap.snap.shortLabel;

  void _openSnapSettings() => SampleEditSnapSheet.show(
        context,
        settings: editSnap,
        onChanged: (next) => setState(() => editSnap = next),
      );

  double _snapSource(double value) {
    if (tool != _SampleTool.trim && tool != _SampleTool.slice) {
      return value.clamp(0.0, 1.0);
    }
    return editSnap.snapSource(value);
  }

  void _handleMenuAction(_SampleMenuAction action) {
    switch (action) {
      case _SampleMenuAction.loop:
        unawaited(_toggleLoop());
      case _SampleMenuAction.warp:
        unawaited(_toggleWarp());
      case _SampleMenuAction.reverse:
        setState(() => reversed = !reversed);
        unawaited(_save());
      case _SampleMenuAction.normalize:
        _normalize();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AutomationEditorTheme.background,
        appBar: AppBar(
          backgroundColor: AutomationEditorTheme.background,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
              '${widget.trackName} · ${widget.clip.sampleName.isEmpty ? 'Sample' : widget.clip.sampleName}',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          actions: [
            TextButton.icon(
              onPressed: _openSnapSettings,
              icon: const Icon(Icons.crop_free, size: 17),
              label: Text('Snap $_snapLabel'),
            ),
            if (saving)
              const Padding(
                  padding: EdgeInsets.all(18),
                  child: SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))),
          ],
        ),
        body: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: Column(children: [
            Container(
              height: 46,
              color: AutomationEditorTheme.dockBackground,
              child: Row(children: [
                _ToolButton(
                    icon: Icons.pan_tool_alt_outlined,
                    label: 'MOVE',
                    tooltip: 'Move and zoom timeline',
                    active: tool == _SampleTool.navigate,
                    onTap: () => setState(() => tool = _SampleTool.navigate)),
                _ToolButton(
                    icon: Icons.content_cut,
                    label: 'TRIM',
                    tooltip: 'Trim',
                    active: tool == _SampleTool.trim,
                    onTap: () => setState(() => tool = _SampleTool.trim)),
                _ToolButton(
                    icon: Icons.show_chart,
                    label: 'FADE',
                    tooltip: 'Fade',
                    active: tool == _SampleTool.fade,
                    onTap: () => setState(() => tool = _SampleTool.fade)),
                _ToolButton(
                    icon: Icons.vertical_split,
                    label: 'SLICE',
                    tooltip: 'Slice',
                    active: tool == _SampleTool.slice,
                    onTap: () => setState(() => tool = _SampleTool.slice)),
                _ToolButton(
                    icon: Icons.tune,
                    label: 'PROCESS',
                    tooltip: 'Clip processing',
                    active: tool == _SampleTool.process,
                    onTap: () => setState(() => tool = _SampleTool.process)),
                const Spacer(),
                _ToolButton(
                    icon: transport.isPlaying ? Icons.stop : Icons.play_arrow,
                    compact: true,
                    tooltip: transport.isPlaying ? 'Stop' : 'Preview',
                    active: transport.isPlaying,
                    onTap: _audition),
                const SizedBox(width: 4),
              ]),
            ),
            Expanded(
                child: _SampleTimeline(
              clipName: widget.clip.sampleName,
              peaks: widget.clip.waveformPeaks,
              clipLengthBeats: widget.clip.lengthBeats,
              naturalLengthBeats: widget.clip.effectiveNaturalLengthBeats,
              playbackContentLengthBeats: _playbackContentLengthBeats,
              start: start,
              end: end,
              fadeIn: fadeIn,
              fadeOut: fadeOut,
              fadeInCurve: fadeInCurve,
              fadeOutCurve: fadeOutCurve,
              gain: gain,
              reversed: reversed,
              pixelsPerBeat: pixelsPerBeat,
              gridStepBeats:
                  SnapGridResolution.adaptive.beatsForZoom(pixelsPerBeat),
              onZoomStart: () => zoomStart = pixelsPerBeat,
              onZoomScale: (scale) => setState(
                  () => pixelsPerBeat = (zoomStart * scale).clamp(24.0, 640.0)),
              clipInteracting: clipInteracting,
              pinchInteracting: pinchInteracting,
              onPinchInteractionChanged: (active) {
                if (pinchInteracting != active) {
                  setState(() => pinchInteracting = active);
                }
              },
              trimToolActive: tool == _SampleTool.trim,
              fadeToolActive: tool == _SampleTool.fade,
              sliceToolActive: tool == _SampleTool.slice,
              sliceMarkers: List.of(sliceMarkers),
              onSliceToggle: _toggleSlice,
              onSliceSelect: _selectSliceMarker,
              selectedSlice: selectedSlice,
              selectedMarker: selectedMarker,
              onSliceMove: _moveSlice,
              onSliceMoveEnd: _saveSlices,
              onSliceAudition: _auditionSlice,
              onPlayheadSeek: transport.seekClipLocal,
              onPlayheadActivate: _audition,
              onClipInteractionChanged: (active) {
                if (clipInteracting != active)
                  setState(() => clipInteracting = active);
              },
              playhead: transport.clipLocalBeat,
              onTrimChanged: (nextStart, nextEnd) {
                setState(() {
                  start = _snapSource(nextStart).clamp(0.0, end - .001);
                  end = _snapSource(nextEnd).clamp(start + .001, 1.0);
                });
                _syncPreviewTransportSpan();
              },
              onFadesChanged: (nextIn, nextOut) => setState(() {
                fadeIn = nextIn;
                fadeOut = nextOut;
              }),
              onCurvesChanged: (nextIn, nextOut) => setState(() {
                fadeInCurve = nextIn;
                fadeOutCurve = nextOut;
              }),
              onEditEnd: _save,
            )),
            _SampleToolCard(
              child: switch (tool) {
                _SampleTool.process => _ProcessPanel(
                    gain: gain,
                    loop: loopContent,
                    repitch: warpRepitch,
                    reversed: reversed,
                    onGainChanged: (value) {
                      setState(() => gain = value);
                      _scheduleSave();
                    },
                    onLoop: () => _handleMenuAction(_SampleMenuAction.loop),
                    onRepitch: () => _handleMenuAction(_SampleMenuAction.warp),
                    onReverse: () =>
                        _handleMenuAction(_SampleMenuAction.reverse),
                    onNormalize: () =>
                        _handleMenuAction(_SampleMenuAction.normalize),
                  ),
                _SampleTool.slice => _SlicePanel(
                    sensitivity: transientSensitivity,
                    autoMode: sliceAutoMode,
                    minGap: sliceMinGap,
                    replaceExisting: sliceReplaceExisting,
                    evenDivisions: sliceEvenDivisions,
                    gridDivision: sliceGridDivision,
                    firstNote: sliceFirstNote,
                    status: sliceStatus,
                    selectedMarkerPosition: selectedMarker == null ||
                            selectedMarker! < 0 ||
                            selectedMarker! >= sliceMarkers.length
                        ? null
                        : sliceMarkers[selectedMarker!],
                    onSensitivityChanged: (value) =>
                        setState(() => transientSensitivity = value),
                    onAutoModeChanged: (value) =>
                        setState(() => sliceAutoMode = value),
                    onMinGapChanged: (value) => setState(() => sliceMinGap = value),
                    onReplaceExistingChanged: (value) =>
                        setState(() => sliceReplaceExisting = value),
                    onEvenDivisionsChanged: (value) =>
                        setState(() => sliceEvenDivisions = value),
                    onGridDivisionChanged: (value) =>
                        setState(() => sliceGridDivision = value),
                    onFirstNoteChanged: (value) =>
                        setState(() => sliceFirstNote = value),
                    onAutoSlice: _autoSlice,
                    onReset: _resetSlices,
                    onDeleteSelected: _deleteSelectedSliceMarker,
                    onNudgeSelected: _nudgeSelectedSliceMarker,
                    onAuditionSelected: _auditionSelectedSliceMarker,
                    onExport: _exportSlices,
                  ),
                _ => _ClipEditPanel(
                    tool: tool,
                    gain: gain,
                    start: start,
                    end: end,
                    fadeIn: fadeIn,
                    fadeOut: fadeOut,
                    fadeInCurve: fadeInCurve,
                    fadeOutCurve: fadeOutCurve,
                    onGainChanged: (value) {
                      setState(() => gain = value);
                      _scheduleSave();
                    },
                    onCurveChanged: (nextIn, nextOut) {
                      setState(() {
                        fadeInCurve = nextIn;
                        fadeOutCurve = nextOut;
                      });
                      _scheduleSave();
                    },
                  ),
              },
            ),
          ]),
        ),
      );
}

String _midiNoteName(int note) {
  const names = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B'
  ];
  return '${names[note % 12]}${note ~/ 12 - 1}';
}

class _SampleTimeline extends StatefulWidget {
  const _SampleTimeline(
      {required this.clipName,
      required this.peaks,
      required this.clipLengthBeats,
      required this.naturalLengthBeats,
      required this.playbackContentLengthBeats,
      required this.start,
      required this.end,
      required this.fadeIn,
      required this.fadeOut,
      required this.fadeInCurve,
      required this.fadeOutCurve,
      required this.gain,
      required this.reversed,
      required this.playhead,
      required this.pixelsPerBeat,
      required this.gridStepBeats,
      required this.onZoomStart,
      required this.onZoomScale,
      required this.clipInteracting,
      required this.pinchInteracting,
      required this.onPinchInteractionChanged,
      required this.trimToolActive,
      required this.fadeToolActive,
      required this.sliceToolActive,
      required this.sliceMarkers,
      required this.onSliceToggle,
      required this.onSliceSelect,
      required this.selectedSlice,
      required this.selectedMarker,
      required this.onSliceMove,
      required this.onSliceMoveEnd,
      required this.onSliceAudition,
      required this.onPlayheadSeek,
      required this.onPlayheadActivate,
      required this.onClipInteractionChanged,
      required this.onTrimChanged,
      required this.onFadesChanged,
      required this.onCurvesChanged,
      required this.onEditEnd});
  final String clipName;
  final List<double> peaks;
  final double clipLengthBeats, naturalLengthBeats, playbackContentLengthBeats;
  final double start,
      end,
      fadeIn,
      fadeOut,
      fadeInCurve,
      fadeOutCurve,
      gain,
      playhead;
  final bool reversed;
  final double pixelsPerBeat;
  final double gridStepBeats;
  final VoidCallback onZoomStart;
  final ValueChanged<double> onZoomScale;
  final bool clipInteracting;
  final bool pinchInteracting;
  final ValueChanged<bool> onPinchInteractionChanged;
  final bool trimToolActive, fadeToolActive;
  final bool sliceToolActive;
  final List<double> sliceMarkers;
  final ValueChanged<double> onSliceToggle;
  final ValueChanged<int> onSliceSelect;
  final int? selectedSlice;
  final int? selectedMarker;
  final void Function(int, double) onSliceMove;
  final VoidCallback onSliceMoveEnd;
  final ValueChanged<double> onSliceAudition;
  final ValueChanged<double> onPlayheadSeek;
  final VoidCallback onPlayheadActivate;
  final ValueChanged<bool> onClipInteractionChanged;
  final void Function(double, double) onTrimChanged,
      onFadesChanged,
      onCurvesChanged;
  final VoidCallback onEditEnd;

  @override
  State<_SampleTimeline> createState() => _SampleTimelineState();
}

class _SampleTimelineState extends State<_SampleTimeline> {
  static const _preRollBeats = 8.0;
  static const _waveformInsetH = 0.0;
  final ScrollController _scroll = ScrollController();
  double? _dragPlayheadBeat;
  bool _draggingPlayhead = false;
  double? _dragSliceValue;

  double get _sourceSpan => math.max(.001, widget.end - widget.start);

  double _usableSourceWidth(double sourceWidth) =>
      math.max(1.0, sourceWidth - _waveformInsetH * 2);

  double _sourceFromPlayheadBeat(double beat) {
    final contentLen = widget.playbackContentLengthBeats;
    if (contentLen <= 0) return widget.start;
    final progress = (beat / contentLen).clamp(0.0, 1.0);
    return widget.reversed
        ? widget.end - progress * _sourceSpan
        : widget.start + progress * _sourceSpan;
  }

  double _playheadBeatFromSource(double sourcePos) {
    final contentLen = widget.playbackContentLengthBeats;
    if (contentLen <= 0) return 0;
    final clamped = sourcePos.clamp(widget.start, widget.end);
    final progress = widget.reversed
        ? (widget.end - clamped) / _sourceSpan
        : (clamped - widget.start) / _sourceSpan;
    return progress.clamp(0.0, 1.0) * contentLen;
  }

  double _playheadX(double originX, double sourceWidth, double beat) =>
      originX +
      _waveformInsetH +
      _usableSourceWidth(sourceWidth) * _sourceFromPlayheadBeat(beat);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(_preRollBeats * widget.pixelsPerBeat);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SampleTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pixelsPerBeat == widget.pixelsPerBeat ||
        !_scroll.hasClients) {
      return;
    }
    final oldOrigin = _preRollBeats * oldWidget.pixelsPerBeat;
    final relativeBeat = (_scroll.offset - oldOrigin) / oldWidget.pixelsPerBeat;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = (_preRollBeats + relativeBeat) * widget.pixelsPerBeat;
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        const rulerHeight = 24.0;
        final clipWidth =
            math.max(64.0, widget.clipLengthBeats * widget.pixelsPerBeat);
        final sourceWidth =
            math.max(64.0, widget.naturalLengthBeats * widget.pixelsPerBeat);
        final timelineWidth = math.max(clipWidth, sourceWidth);
        final originX = _preRollBeats * widget.pixelsPerBeat;
        final canvasWidth = math.max(
          box.maxWidth,
          originX + timelineWidth + widget.pixelsPerBeat * 8,
        );
        final playheadBeat = (_dragPlayheadBeat ?? widget.playhead)
            .clamp(0.0, widget.playbackContentLengthBeats);
        final playheadX = _playheadX(originX, sourceWidth, playheadBeat);
        final usableWidth = _usableSourceWidth(sourceWidth);
        return _RawPinchZoom(
          onStart: widget.onZoomStart,
          onScale: widget.onZoomScale,
          onPinchChanged: widget.onPinchInteractionChanged,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            physics: widget.clipInteracting ||
                    widget.pinchInteracting ||
                    _draggingPlayhead
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            child: SizedBox(
                width: canvasWidth,
                height: box.maxHeight,
                child: Stack(clipBehavior: Clip.none, children: [
                  Column(children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => widget.onPlayheadSeek(
                        _playheadBeatFromSource(
                          ((details.localPosition.dx - originX - _waveformInsetH) /
                                  usableWidth)
                              .clamp(0.0, 1.0),
                        ),
                      ),
                      child: CustomPaint(
                        painter: _SampleRulerPainter(
                          pixelsPerBeat: widget.pixelsPerBeat,
                          originX: originX,
                          clipLengthBeats: widget.clipLengthBeats,
                        ),
                        child:
                            SizedBox(width: canvasWidth, height: rulerHeight),
                      ),
                    ),
                    Expanded(
                        child: CustomPaint(
                            painter: _SampleLanePainter(
                                pixelsPerBeat: widget.pixelsPerBeat,
                                originX: originX,
                                gridStepBeats: widget.gridStepBeats),
                            child: Stack(children: [
                              Positioned(
                                left: originX,
                                width: sourceWidth,
                                top: 0,
                                bottom: 0,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: EditableWaveform(
                                      peaks: widget.peaks,
                                      start: widget.start,
                                      end: widget.end,
                                      fadeIn: widget.fadeIn,
                                      fadeOut: widget.fadeOut,
                                      fadeInCurve: widget.fadeInCurve,
                                      fadeOutCurve: widget.fadeOutCurve,
                                      gain: widget.gain,
                                      reversed: widget.reversed,
                                      trimToolActive: false,
                                      fadeToolActive: widget.fadeToolActive,
                                      sliceToolActive: widget.sliceToolActive,
                                      sliceMarkers: const [],
                                      onSliceToggle: widget.onSliceToggle,
                                      selectedSlice: null,
                                      onSliceMove: widget.onSliceMove,
                                      onSliceMoveEnd: widget.onSliceMoveEnd,
                                      onSliceAudition: widget.onSliceAudition,
                                      playhead: _sourceFromPlayheadBeat(playheadBeat),
                                      onTrimChanged: widget.onTrimChanged,
                                      onFadesChanged: widget.onFadesChanged,
                                      onCurvesChanged: widget.onCurvesChanged,
                                      onInteractionChanged:
                                          widget.onClipInteractionChanged,
                                      onEditEnd: widget.onEditEnd),
                                ),
                              ),
                            ]))),
                  ]),
                  if (widget.trimToolActive)
                    for (final edge in [
                      (isStart: true, value: widget.start),
                      (isStart: false, value: widget.end),
                    ])
                      Positioned(
                        left: originX +
                            _waveformInsetH +
                            usableWidth * edge.value -
                            ArrangementLoopRegionTheme.hitWidth / 2,
                        top: (rulerHeight -
                                ArrangementLoopRegionTheme.pillSize) /
                            2,
                        bottom: 0,
                        width: ArrangementLoopRegionTheme.hitWidth,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragUpdate: (details) {
                            final delta = details.delta.dx / usableWidth;
                            if (edge.isStart) {
                              widget.onTrimChanged(
                                (widget.start + delta)
                                    .clamp(0.0, widget.end - .001),
                                widget.end,
                              );
                            } else {
                              widget.onTrimChanged(
                                widget.start,
                                (widget.end + delta)
                                    .clamp(widget.start + .001, 1.0),
                              );
                            }
                          },
                          onHorizontalDragEnd: (_) => widget.onEditEnd(),
                          onHorizontalDragCancel: widget.onEditEnd,
                          child:
                              Stack(alignment: Alignment.topCenter, children: [
                            Positioned(
                              top: ArrangementLoopRegionTheme.pillSize / 2,
                              bottom: 0,
                              width: 2,
                              child: ColoredBox(
                                  color: ArrangementLoopRegionTheme.color),
                            ),
                            const ArrangementLoopRegionPill(),
                          ]),
                        ),
                      ),
                  if (widget.sliceToolActive)
                    for (final entry in widget.sliceMarkers.indexed)
                      Positioned(
                        left: originX +
                            _waveformInsetH +
                            usableWidth *
                                (widget.start +
                                    (widget.end - widget.start) * entry.$2) -
                            ArrangementLoopRegionTheme.hitWidth / 2,
                        top: (rulerHeight -
                                ArrangementLoopRegionTheme.pillSize) /
                            2,
                        bottom: 0,
                        width: ArrangementLoopRegionTheme.hitWidth,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onSliceSelect(entry.$1),
                          onHorizontalDragStart: (_) =>
                              _dragSliceValue = entry.$2,
                          onHorizontalDragUpdate: (details) {
                            final sourceSpan =
                                math.max(.001, widget.end - widget.start);
                            _dragSliceValue = ((_dragSliceValue ?? entry.$2) +
                                    details.delta.dx / usableWidth / sourceSpan)
                                .clamp(.001, .999);
                            widget.onSliceMove(entry.$1, _dragSliceValue!);
                          },
                          onHorizontalDragEnd: (_) {
                            _dragSliceValue = null;
                            widget.onSliceMoveEnd();
                          },
                          onHorizontalDragCancel: () => _dragSliceValue = null,
                          child:
                              Stack(alignment: Alignment.topCenter, children: [
                            Positioned(
                              top: ArrangementLoopRegionTheme.pillSize / 2,
                              bottom: 0,
                              width: 2,
                              child: ColoredBox(
                                  color: widget.selectedMarker == entry.$1
                                      ? Colors.white
                                      : ArrangementLoopRegionTheme.color),
                            ),
                            const ArrangementLoopRegionPill(),
                          ]),
                        ),
                      ),
                  if (!widget.sliceToolActive && widget.sliceMarkers.isNotEmpty)
                    for (final marker in widget.sliceMarkers)
                      Positioned(
                        left: originX +
                            _waveformInsetH +
                            usableWidth *
                                (widget.start +
                                    (widget.end - widget.start) * marker) -
                            .5,
                        top: rulerHeight,
                        bottom: 0,
                        width: 1,
                        child: ColoredBox(
                          color: ArrangementLoopRegionTheme.color
                              .withValues(alpha: .65),
                        ),
                      ),
                  Positioned(
                    left: playheadX - editorVirtualPlayheadLineWidth / 2,
                    top: rulerHeight / 2,
                    bottom: 0,
                    width: editorVirtualPlayheadLineWidth,
                    child: const ColoredBox(
                        color: EditorVirtualPlayheadTheme.color),
                  ),
                  Positioned(
                    left: math.max(0, playheadX - 20),
                    top: 0,
                    width: 40,
                    height: rulerHeight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onPlayheadActivate,
                      onHorizontalDragStart: (_) => setState(() {
                        _dragPlayheadBeat = playheadBeat;
                        _draggingPlayhead = true;
                      }),
                      onHorizontalDragUpdate: (details) {
                        final beatDelta = widget.reversed
                            ? -details.delta.dx / usableWidth *
                                widget.playbackContentLengthBeats /
                                _sourceSpan
                            : details.delta.dx /
                                usableWidth *
                                widget.playbackContentLengthBeats /
                                _sourceSpan;
                        final next = ((_dragPlayheadBeat ?? playheadBeat) +
                                beatDelta)
                            .clamp(0.0, widget.playbackContentLengthBeats);
                        setState(() => _dragPlayheadBeat = next);
                        widget.onPlayheadSeek(next);
                      },
                      onHorizontalDragEnd: (_) => setState(() {
                        _dragPlayheadBeat = null;
                        _draggingPlayhead = false;
                      }),
                      onHorizontalDragCancel: () => setState(() {
                        _dragPlayheadBeat = null;
                        _draggingPlayhead = false;
                      }),
                      child: const EditorVirtualPlayheadPill(),
                    ),
                  ),
                ])),
          ),
        );
      });
}

class _RawPinchZoom extends StatefulWidget {
  const _RawPinchZoom(
      {required this.child,
      required this.onStart,
      required this.onScale,
      required this.onPinchChanged});
  final Widget child;
  final VoidCallback onStart;
  final ValueChanged<double> onScale;
  final ValueChanged<bool> onPinchChanged;
  @override
  State<_RawPinchZoom> createState() => _RawPinchZoomState();
}

class _RawPinchZoomState extends State<_RawPinchZoom> {
  final positions = <int, Offset>{};
  double initialDistance = 1;

  double get distance {
    if (positions.length < 2) return 1;
    final points = positions.values.take(2).toList();
    return math.max(12, (points[0] - points[1]).distance);
  }

  void down(PointerDownEvent event) {
    positions[event.pointer] = event.localPosition;
    if (positions.length == 2) {
      initialDistance = distance;
      widget.onStart();
      widget.onPinchChanged(true);
    }
  }

  void move(PointerMoveEvent event) {
    if (!positions.containsKey(event.pointer)) return;
    positions[event.pointer] = event.localPosition;
    if (positions.length >= 2) widget.onScale(distance / initialDistance);
  }

  void remove(PointerEvent event) {
    positions.remove(event.pointer);
    if (positions.length < 2) widget.onPinchChanged(false);
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: down,
        onPointerMove: move,
        onPointerUp: remove,
        onPointerCancel: remove,
        child: widget.child,
      );
}

class _SampleRulerPainter extends CustomPainter {
  const _SampleRulerPainter({
    required this.pixelsPerBeat,
    required this.originX,
    required this.clipLengthBeats,
  });
  final double pixelsPerBeat;
  final double originX;
  final double clipLengthBeats;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = AutomationEditorTheme.rulerBackground);
    final active = Rect.fromLTWH(originX, size.height - 3,
        math.max(0, clipLengthBeats * pixelsPerBeat), 3);
    canvas.drawRect(active,
        Paint()..color = AutomationEditorTheme.accent.withValues(alpha: .8));
    final text = TextPainter(textDirection: TextDirection.ltr);
    final firstBeat = (-originX / pixelsPerBeat).floor();
    final lastBeat = ((size.width - originX) / pixelsPerBeat).ceil();
    for (var beat = firstBeat; beat <= lastBeat; beat++) {
      final x = originX + beat * pixelsPerBeat;
      final bar = beat % 4 == 0;
      canvas.drawLine(
          Offset(x, bar ? 0 : 12),
          Offset(x, size.height),
          Paint()
            ..color = bar ? Colors.white24 : Colors.white10
            ..strokeWidth = 1);
      if (pixelsPerBeat >= 42 || bar) {
        final barIndex = beat ~/ 4;
        final beatInBar = beat % 4;
        text.text = TextSpan(
            text: bar
                ? (barIndex < 0 ? '$barIndex' : '${barIndex + 1}')
                : barIndex < 0
                    ? '$barIndex.${beatInBar + 1}'
                    : '${barIndex + 1}.${beatInBar + 1}',
            style: TextStyle(
                fontSize: bar ? 9 : 8,
                fontWeight: beat == 0 ? FontWeight.w700 : FontWeight.w500,
                color: beat >= 0 && beat <= clipLengthBeats
                    ? AutomationEditorTheme.accent
                    : AutomationEditorTheme.labelMuted));
        text.layout();
        text.paint(canvas, Offset(x + 5, 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SampleRulerPainter old) =>
      old.pixelsPerBeat != pixelsPerBeat ||
      old.originX != originX ||
      old.clipLengthBeats != clipLengthBeats;
}

class _SampleLanePainter extends CustomPainter {
  const _SampleLanePainter(
      {required this.pixelsPerBeat,
      required this.originX,
      required this.gridStepBeats});
  final double pixelsPerBeat;
  final double originX;
  final double gridStepBeats;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = AutomationEditorTheme.background);
    final step = math.max(.03125, gridStepBeats);
    final firstIndex = ((-originX / pixelsPerBeat) / step).floor();
    final lastIndex = (((size.width - originX) / pixelsPerBeat) / step).ceil();
    for (var index = firstIndex; index <= lastIndex; index++) {
      final beat = index * step;
      final isBar = (beat % 4).abs() < .0001;
      final isBeat = (beat - beat.round()).abs() < .0001;
      canvas.drawLine(
          Offset(originX + beat * pixelsPerBeat, 0),
          Offset(originX + beat * pixelsPerBeat, size.height),
          Paint()
            ..color = isBar
                ? AutomationEditorTheme.gridBar
                : isBeat
                    ? AutomationEditorTheme.gridBeat
                    : AutomationEditorTheme.gridSubdivision
            ..strokeWidth = isBar ? 1 : 0.5);
    }
    canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()..color = Colors.white.withValues(alpha: .035));
  }

  @override
  bool shouldRepaint(covariant _SampleLanePainter old) =>
      old.pixelsPerBeat != pixelsPerBeat ||
      old.originX != originX ||
      old.gridStepBeats != gridStepBeats;
}

class _ToolButton extends StatelessWidget {
  const _ToolButton(
      {required this.icon,
      required this.tooltip,
      required this.onTap,
      this.label,
      this.compact = false,
      this.active = false});
  final IconData icon;
  final String tooltip;
  final String? label;
  final VoidCallback onTap;
  final bool active, compact;
  @override
  Widget build(BuildContext context) => Tooltip(
      message: tooltip,
      child: Material(
        color: active ? AutomationEditorTheme.dockActive : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
              width: compact ? 42 : 57,
              height: 46,
              child: label == null
                  ? Icon(icon,
                      size: 21,
                      color: active
                          ? AutomationEditorTheme.dockIconActive
                          : AutomationEditorTheme.dockIcon)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Icon(icon,
                              size: 18,
                              color: active
                                  ? AutomationEditorTheme.dockIconActive
                                  : AutomationEditorTheme.dockIcon),
                          const SizedBox(height: 2),
                          Text(label!,
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? AutomationEditorTheme.dockIconActive
                                      : AutomationEditorTheme.dockIcon)),
                        ])),
        ),
      ));
}

class _SampleToolCard extends StatelessWidget {
  const _SampleToolCard({required this.child});
  final Widget child;

  static const height = 236.0;
  static const _borderColor = Color(0xff3b3b49);

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        decoration: BoxDecoration(
          color: AutomationEditorTheme.panelBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: child,
      );
}

class _ToolCardHeader extends StatelessWidget {
  const _ToolCardHeader({required this.title, this.hint});
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: .5)),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(hint!,
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: ArrangementLoopRegionTheme.color.withValues(alpha: .85),
                    letterSpacing: .25)),
          ],
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: .06),
          ),
        ],
      );
}

class _ClipEditPanel extends StatelessWidget {
  const _ClipEditPanel({
    required this.tool,
    required this.gain,
    required this.start,
    required this.end,
    required this.fadeIn,
    required this.fadeOut,
    required this.fadeInCurve,
    required this.fadeOutCurve,
    required this.onGainChanged,
    required this.onCurveChanged,
  });
  final _SampleTool tool;
  final double gain, start, end, fadeIn, fadeOut, fadeInCurve, fadeOutCurve;
  final ValueChanged<double> onGainChanged;
  final void Function(double, double) onCurveChanged;

  ({String title, String hint}) get _copy => switch (tool) {
        _SampleTool.navigate => (
            title: 'TIMELINE',
            hint: 'PINCH TO ZOOM  •  DRAG TO PAN',
          ),
        _SampleTool.trim => (
            title: 'TRIM BOUNDS',
            hint: 'DRAG START AND END HANDLES',
          ),
        _SampleTool.fade => (
            title: 'FADE ENVELOPE',
            hint: 'DRAG FADE HANDLES ON WAVEFORM',
          ),
        _ => (title: 'CLIP EDITOR', hint: ''),
      };

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ToolCardHeader(title: copy.title, hint: copy.hint),
        Expanded(child: tool == _SampleTool.fade ? _fadeBody() : _defaultBody()),
      ],
    );
  }

  Widget _defaultBody() => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 68,
            child: Center(
              child: RotaryKnob(
                label: 'GAIN',
                value: (gain / 4).clamp(0, 1),
                size: 56,
                accentColor: AutomationEditorTheme.accent,
                displayValue: '${(gain * 100).round()}%',
                onChanged: (value) => onGainChanged(value * 4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ProcessGroup(
              title: 'BOUNDS',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InlineReadout(
                          label: 'START', value: '${(start * 100).round()}%'),
                    ),
                    Expanded(
                      child: _InlineReadout(
                          label: 'END', value: '${(end * 100).round()}%'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ProcessGroup(
              title: 'FADES',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InlineReadout(
                          label: 'FADE IN',
                          value: '${(fadeIn * 100).round()}%'),
                    ),
                    Expanded(
                      child: _InlineReadout(
                          label: 'FADE OUT',
                          value: '${(fadeOut * 100).round()}%'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _fadeBody() => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FadeCurveSelector(
              label: 'Fade In',
              percent: fadeIn,
              value: _FadeCurveKindX.fromValue(fadeInCurve),
              fadeOut: false,
              onChanged: (kind) => onCurveChanged(kind.value, fadeOutCurve),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FadeCurveSelector(
              label: 'Fade Out',
              percent: fadeOut,
              value: _FadeCurveKindX.fromValue(fadeOutCurve),
              fadeOut: true,
              onChanged: (kind) => onCurveChanged(fadeInCurve, kind.value),
            ),
          ),
        ],
      );
}

class _FadeCurveSelector extends StatelessWidget {
  const _FadeCurveSelector({
    required this.label,
    required this.percent,
    required this.value,
    required this.fadeOut,
    required this.onChanged,
  });
  final String label;
  final double percent;
  final _FadeCurveKind value;
  final bool fadeOut;
  final ValueChanged<_FadeCurveKind> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text(label,
                  style: const TextStyle(
                      color: AutomationEditorTheme.labelMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .35)),
              const Spacer(),
              Text('${(percent * 100).round()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            Expanded(
              child: Column(children: [
                Expanded(
                  child: Row(children: [
                    Expanded(child: _curveButton(_FadeCurveKind.linear)),
                    const SizedBox(width: 6),
                    Expanded(child: _curveButton(_FadeCurveKind.quadratic)),
                  ]),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Row(children: [
                    Expanded(child: _curveButton(_FadeCurveKind.cubic)),
                    const SizedBox(width: 6),
                    Expanded(child: _curveButton(_FadeCurveKind.smooth)),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      );

  Widget _curveButton(_FadeCurveKind kind) => _FadeCurveIconButton(
        kind: kind,
        active: kind == value,
        fadeOut: fadeOut,
        onTap: () => onChanged(kind),
      );
}

class _FadeCurveIconButton extends StatelessWidget {
  const _FadeCurveIconButton({
    required this.kind,
    required this.active,
    required this.fadeOut,
    required this.onTap,
  });
  final _FadeCurveKind kind;
  final bool active;
  final bool fadeOut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active
            ? AutomationEditorTheme.accent.withValues(alpha: .16)
            : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: active
                    ? AutomationEditorTheme.accent.withValues(alpha: .55)
                    : Colors.white.withValues(alpha: .08),
              ),
            ),
            child: CustomPaint(
              painter: _FadeCurveIconPainter(
                kind: kind,
                fadeOut: fadeOut,
                color: active ? AutomationEditorTheme.accent : Colors.white60,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
}

class _FadeCurveIconPainter extends CustomPainter {
  const _FadeCurveIconPainter({
    required this.kind,
    required this.fadeOut,
    required this.color,
  });
  final _FadeCurveKind kind;
  final bool fadeOut;
  final Color color;

  double _shape(double value) => switch (kind) {
        _FadeCurveKind.linear => value,
        _FadeCurveKind.quadratic => value * value,
        _FadeCurveKind.cubic => value * value * value,
        _FadeCurveKind.smooth => value * value * (3 - 2 * value),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(8, 6, size.width - 16, size.height - 12);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .10)
      ..strokeWidth = 1;
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, grid);
    canvas.drawLine(rect.bottomLeft, rect.topLeft, grid);

    final path = Path();
    for (var i = 0; i <= 24; i++) {
      final t = i / 24;
      final x = rect.left + rect.width * t;
      final shaped = fadeOut ? 1 - _shape(1 - t) : _shape(t);
      final y = rect.bottom - rect.height * shaped;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FadeCurveIconPainter oldDelegate) =>
      oldDelegate.kind != kind ||
      oldDelegate.fadeOut != fadeOut ||
      oldDelegate.color != color;
}

class _InlineReadout extends StatelessWidget {
  const _InlineReadout({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AutomationEditorTheme.labelMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3)),
        ],
      );
}

class _ProcessPanel extends StatefulWidget {
  const _ProcessPanel({
    required this.gain,
    required this.loop,
    required this.repitch,
    required this.reversed,
    required this.onGainChanged,
    required this.onLoop,
    required this.onRepitch,
    required this.onReverse,
    required this.onNormalize,
  });
  final double gain;
  final bool loop, repitch, reversed;
  final ValueChanged<double> onGainChanged;
  final VoidCallback onLoop, onRepitch, onReverse, onNormalize;

  @override
  State<_ProcessPanel> createState() => _ProcessPanelState();
}

enum _ProcessTab { level, playback, warp, apply }

class _ProcessPanelState extends State<_ProcessPanel> {
  _ProcessTab _tab = _ProcessTab.level;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ToolCardHeader(title: 'CLIP PROCESSING'),
          const SizedBox(height: 6),
          _ProcessTabBar(
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildTabBody()),
        ],
      );

  Widget _buildTabBody() => switch (_tab) {
        _ProcessTab.level => Center(
            child: RotaryKnob(
              label: 'GAIN',
              value: (widget.gain / 4).clamp(0, 1),
              size: 72,
              accentColor: AutomationEditorTheme.accent,
              displayValue: '${(widget.gain * 100).round()}%',
              onChanged: (value) => widget.onGainChanged(value * 4),
            ),
          ),
        _ProcessTab.playback => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniToggle(
                    label: 'Loop clip content',
                    active: widget.loop,
                    onTap: widget.onLoop),
                _MiniToggle(
                    label: 'Reverse playback',
                    active: widget.reversed,
                    onTap: widget.onReverse),
              ],
            ),
          ),
        _ProcessTab.warp => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniToggle(
                    label: 'Repitch to clip length',
                    active: widget.repitch,
                    onTap: widget.onRepitch),
                const SizedBox(height: 6),
                const _EngineField(),
                const SizedBox(height: 6),
                Text(
                  widget.repitch
                      ? 'Sample stretches to fit the clip on the timeline.'
                      : 'Sample plays at its natural speed and length.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9,
                      height: 1.35,
                      color: AutomationEditorTheme.labelMuted
                          .withValues(alpha: .9)),
                ),
              ],
            ),
          ),
        _ProcessTab.apply => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniToggle(
                  label: 'Normalize peak level',
                  icon: Icons.equalizer,
                  onTap: widget.onNormalize,
                ),
                const SizedBox(height: 8),
                Text(
                  'Scales gain so the loudest peak hits 0 dBFS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 9,
                      height: 1.35,
                      color: AutomationEditorTheme.labelMuted
                          .withValues(alpha: .9)),
                ),
              ],
            ),
          ),
      };
}

class _ProcessTabBar extends StatelessWidget {
  const _ProcessTabBar({required this.selected, required this.onSelected});
  final _ProcessTab selected;
  final ValueChanged<_ProcessTab> onSelected;

  static const _specs = <(_ProcessTab, String, IconData)>[
    (_ProcessTab.level, 'Level', Icons.tune),
    (_ProcessTab.playback, 'Playback', Icons.repeat),
    (_ProcessTab.warp, 'Warp', Icons.speed),
    (_ProcessTab.apply, 'Apply', Icons.auto_fix_high),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 30,
        child: Row(
          children: [
            for (var i = 0; i < _specs.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _ProcessTabChip(
                  label: _specs[i].$2,
                  icon: _specs[i].$3,
                  active: selected == _specs[i].$1,
                  onTap: () => onSelected(_specs[i].$1),
                ),
              ),
            ],
          ],
        ),
      );
}

class _ProcessTabChip extends StatelessWidget {
  const _ProcessTabChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active
            ? AutomationEditorTheme.accent.withValues(alpha: .16)
            : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: active
                    ? AutomationEditorTheme.accent.withValues(alpha: .55)
                    : Colors.white.withValues(alpha: .08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 12,
                    color: active
                        ? AutomationEditorTheme.accent
                        : Colors.white38),
                const SizedBox(width: 3),
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                        color: active
                            ? AutomationEditorTheme.accent
                            : Colors.white54)),
              ],
            ),
          ),
        ),
      );
}

class _SlicePanel extends StatefulWidget {
  const _SlicePanel({
    required this.sensitivity,
    required this.autoMode,
    required this.minGap,
    required this.replaceExisting,
    required this.evenDivisions,
    required this.gridDivision,
    required this.firstNote,
    required this.status,
    required this.selectedMarkerPosition,
    required this.onSensitivityChanged,
    required this.onAutoModeChanged,
    required this.onMinGapChanged,
    required this.onReplaceExistingChanged,
    required this.onEvenDivisionsChanged,
    required this.onGridDivisionChanged,
    required this.onFirstNoteChanged,
    required this.onAutoSlice,
    required this.onReset,
    required this.onDeleteSelected,
    required this.onNudgeSelected,
    required this.onAuditionSelected,
    required this.onExport,
  });
  final double sensitivity;
  final _SliceAutoMode autoMode;
  final double minGap;
  final bool replaceExisting;
  final int evenDivisions;
  final SampleEditSnap gridDivision;
  final int firstNote;
  final String? status;
  final double? selectedMarkerPosition;
  final ValueChanged<double> onSensitivityChanged;
  final ValueChanged<_SliceAutoMode> onAutoModeChanged;
  final ValueChanged<double> onMinGapChanged;
  final ValueChanged<bool> onReplaceExistingChanged;
  final ValueChanged<int> onEvenDivisionsChanged;
  final ValueChanged<SampleEditSnap> onGridDivisionChanged;
  final ValueChanged<int> onFirstNoteChanged;
  final VoidCallback onAutoSlice, onReset, onDeleteSelected;
  final ValueChanged<int> onNudgeSelected;
  final VoidCallback onAuditionSelected, onExport;

  @override
  State<_SlicePanel> createState() => _SlicePanelState();
}

class _SlicePanelState extends State<_SlicePanel> {
  _SliceTab _tab = _SliceTab.auto;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ToolCardHeader(
            title: 'SLICING',
            hint: 'TAP TO ADD  •  TAP MARKER TO SELECT  •  DRAG TO MOVE',
          ),
          const SizedBox(height: 6),
          _SliceTabBar(
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildBody()),
        ],
      );

  Widget _buildBody() => switch (_tab) {
        _SliceTab.auto => _autoBody(),
        _SliceTab.edit => _editBody(),
        _SliceTab.map => _mapBody(),
      };

  Widget _autoBody() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            _SliceChoiceChip(
                label: 'Transient',
                active: widget.autoMode == _SliceAutoMode.transient,
                onTap: () =>
                    widget.onAutoModeChanged(_SliceAutoMode.transient)),
            const SizedBox(width: 5),
            _SliceChoiceChip(
                label: 'Even',
                active: widget.autoMode == _SliceAutoMode.even,
                onTap: () => widget.onAutoModeChanged(_SliceAutoMode.even)),
            const SizedBox(width: 5),
            _SliceChoiceChip(
                label: 'Grid',
                active: widget.autoMode == _SliceAutoMode.grid,
                onTap: () => widget.onAutoModeChanged(_SliceAutoMode.grid)),
          ]),
          const SizedBox(height: 10),
          Expanded(child: _autoControl()),
          Row(children: [
            Expanded(
              child: _SliceCommandButton(
                label: 'Auto Slice',
                icon: Icons.auto_fix_high,
                primary: true,
                onTap: widget.onAutoSlice,
              ),
            ),
            const SizedBox(width: 6),
            _SliceChoiceChip(
              label: widget.replaceExisting ? 'Replace' : 'Add',
              active: widget.replaceExisting,
              onTap: () =>
                  widget.onReplaceExistingChanged(!widget.replaceExisting),
            ),
          ]),
          if (widget.status != null) ...[
            const SizedBox(height: 7),
            Text(widget.status!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AutomationEditorTheme.labelMuted
                        .withValues(alpha: .95),
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ],
      );

  Widget _autoControl() => switch (widget.autoMode) {
        _SliceAutoMode.transient => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SliceSliderRow(
                label: 'Sensitivity',
                valueLabel: '${(widget.sensitivity * 100).round()}%',
                value: widget.sensitivity,
                onChanged: widget.onSensitivityChanged,
              ),
              _SliceSliderRow(
                label: 'Min gap',
                valueLabel: '${(widget.minGap * 100).round()}%',
                value: widget.minGap,
                onChanged: (value) =>
                    widget.onMinGapChanged(value.clamp(.01, .20)),
              ),
            ],
          ),
        _SliceAutoMode.even => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SliceSliderRow(
                label: 'Divisions',
                valueLabel: '${widget.evenDivisions}',
                value: (widget.evenDivisions - 2) / 30,
                onChanged: (value) =>
                    widget.onEvenDivisionsChanged((2 + value * 30).round()),
              ),
            ],
          ),
        _SliceAutoMode.grid => Center(
            child: Row(children: [
              const Text('Grid division',
                  style: TextStyle(
                      color: AutomationEditorTheme.labelMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              DropdownButton<SampleEditSnap>(
                value: widget.gridDivision,
                underline: const SizedBox.shrink(),
                dropdownColor: AutomationEditorTheme.panelBackground,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                items: SampleEditSnap.values
                    .where((value) => value != SampleEditSnap.off)
                    .map((value) => DropdownMenuItem(
                        value: value, child: Text(value.shortLabel)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) widget.onGridDivisionChanged(value);
                },
              ),
            ]),
          ),
      };

  Widget _editBody() {
    final selected = widget.selectedMarkerPosition;
    final enabled = selected != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          enabled
              ? 'Selected marker ${(selected * 100).round()}%'
              : 'Select a marker on the waveform to edit it.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Row(children: [
          Expanded(
            child: _SliceCommandButton(
              label: 'Audition',
              icon: Icons.play_arrow,
              onTap: enabled ? widget.onAuditionSelected : null,
            ),
          ),
          const SizedBox(width: 6),
          _SliceIconButton(
              icon: Icons.chevron_left,
              tooltip: 'Nudge left',
              onTap: enabled ? () => widget.onNudgeSelected(-1) : null),
          const SizedBox(width: 5),
          _SliceIconButton(
              icon: Icons.chevron_right,
              tooltip: 'Nudge right',
              onTap: enabled ? () => widget.onNudgeSelected(1) : null),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: _SliceCommandButton(
              label: 'Delete Marker',
              icon: Icons.delete_outline,
              onTap: enabled ? widget.onDeleteSelected : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SliceCommandButton(
              label: 'Reset Slices',
              icon: Icons.restart_alt,
              onTap: widget.onReset,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _mapBody() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Text('First pad',
                style: TextStyle(
                    color: AutomationEditorTheme.labelMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            DropdownButton<int>(
              isDense: true,
              value: widget.firstNote,
              underline: const SizedBox.shrink(),
              dropdownColor: AutomationEditorTheme.panelBackground,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              items: [24, 36, 48, 60]
                  .map((note) => DropdownMenuItem(
                      value: note, child: Text(_midiNoteName(note))))
                  .toList(),
              onChanged: (value) {
                if (value != null) widget.onFirstNoteChanged(value);
              },
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'Exports the current slice regions upward from ${_midiNoteName(widget.firstNote)}.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                height: 1.3,
                color: AutomationEditorTheme.labelMuted.withValues(alpha: .9)),
          ),
          Expanded(
            child: Center(
              child: _SliceCommandButton(
                label: 'Send to Drum Machine',
                icon: Icons.grid_view_rounded,
                primary: true,
                onTap: widget.onExport,
              ),
            ),
          ),
        ],
      );
}

class _SliceTabBar extends StatelessWidget {
  const _SliceTabBar({required this.selected, required this.onSelected});
  final _SliceTab selected;
  final ValueChanged<_SliceTab> onSelected;

  static const _tabs = <(_SliceTab, String, IconData)>[
    (_SliceTab.auto, 'Auto', Icons.auto_fix_high),
    (_SliceTab.edit, 'Edit', Icons.edit),
    (_SliceTab.map, 'Map', Icons.grid_view_rounded),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .035),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Row(children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: _SliceTabButton(
                  label: _tabs[i].$2,
                  icon: _tabs[i].$3,
                  active: selected == _tabs[i].$1,
                  onTap: () => onSelected(_tabs[i].$1),
                ),
              ),
          ]),
        ),
      );
}

class _SliceTabButton extends StatelessWidget {
  const _SliceTabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active
            ? ArrangementLoopRegionTheme.color.withValues(alpha: .16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 14,
                        color: active
                            ? ArrangementLoopRegionTheme.color
                            : Colors.white54),
                    const SizedBox(width: 5),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .25,
                            color: active
                                ? ArrangementLoopRegionTheme.color
                                : Colors.white60)),
                  ],
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: active
                          ? ArrangementLoopRegionTheme.color
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _SliceChoiceChip extends StatelessWidget {
  const _SliceChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active
            ? ArrangementLoopRegionTheme.color.withValues(alpha: .18)
            : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            height: 34,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: active
                    ? ArrangementLoopRegionTheme.color.withValues(alpha: .55)
                    : Colors.white.withValues(alpha: .08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                        color: active
                            ? ArrangementLoopRegionTheme.color
                            : Colors.white54)),
              ],
            ),
          ),
        ),
      );
}

class _SliceSliderRow extends StatelessWidget {
  const _SliceSliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.onChanged,
  });
  final String label, valueLabel;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
          width: 84,
          child: Text(label,
              style: const TextStyle(
                  color: AutomationEditorTheme.labelMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              activeColor: ArrangementLoopRegionTheme.color,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(valueLabel,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ),
      ]);
}

class _SliceCommandButton extends StatelessWidget {
  const _SliceCommandButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final accent = ArrangementLoopRegionTheme.color;
    return Material(
      color: !enabled
          ? Colors.white.withValues(alpha: .025)
          : primary
              ? accent.withValues(alpha: .20)
              : Colors.white.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: !enabled
                      ? Colors.white24
                      : primary
                          ? accent
                          : Colors.white60),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: !enabled
                            ? Colors.white24
                            : primary
                                ? accent
                                : Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliceIconButton extends StatelessWidget {
  const _SliceIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: onTap == null ? .025 : .05),
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            borderRadius: BorderRadius.circular(7),
            onTap: onTap,
            child: SizedBox(
              width: 34,
              height: 36,
              child: Icon(icon,
                  size: 18, color: onTap == null ? Colors.white24 : Colors.white70),
            ),
          ),
        ),
      );
}

class _ProcessGroup extends StatelessWidget {
  const _ProcessGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AutomationEditorTheme.labelMuted,
                    letterSpacing: .35)),
            const SizedBox(height: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ],
        ),
      );
}

class _MiniToggle extends StatelessWidget {
  const _MiniToggle(
      {required this.label,
      required this.onTap,
      this.active = false,
      this.icon});
  final String label;
  final VoidCallback onTap;
  final bool active;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onTap,
          child: Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: active
                  ? AutomationEditorTheme.accent.withValues(alpha: .22)
                  : Colors.white.withValues(alpha: .035),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: Colors.white60),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 9,
                        color: active
                            ? AutomationEditorTheme.accent
                            : Colors.white70)),
              ),
              if (icon == null)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        active ? AutomationEditorTheme.accent : Colors.white24,
                  ),
                ),
            ]),
          ),
        ),
      );
}

class _EngineField extends StatelessWidget {
  const _EngineField();
  @override
  Widget build(BuildContext context) => Container(
        height: 26,
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ENGINE',
                style: TextStyle(
                    fontSize: 7, color: AutomationEditorTheme.labelMuted)),
            Text('Resample',
                style: TextStyle(fontSize: 9, color: Colors.white70)),
          ],
        ),
      );
}
