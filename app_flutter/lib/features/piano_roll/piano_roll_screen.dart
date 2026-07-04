import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../editor/clip_editor_transport.dart';
import '../editor/timeline_marker_layer.dart';
import '../play/play_deck.dart';
import '../play/play_deck_layout.dart';
import 'piano_roll_edit_sheet.dart';
import 'piano_roll_grid_sheet.dart';
import 'editor_view_range.dart';
import 'midi_lane_layout.dart';
import 'piano_roll_metrics.dart';
import 'piano_roll_note_audition.dart';
import 'piano_roll_note_ops.dart';
import 'piano_roll_scale.dart';
import 'piano_roll_theme.dart';
import 'piano_roll_tool_dock.dart';
import 'piano_roll_viewport.dart';

class PianoRollScreen extends StatefulWidget {
  const PianoRollScreen({
    super.key,
    required this.bridge,
    required this.clip,
    required this.trackName,
    required this.bpm,
    required this.onSnapshot,
    required this.savedArrangementPlayhead,
    this.drumAnchorPitch,
    this.drumLaneLayout,
  });

  final EngineBridge bridge;
  final MidiClipSnapshot clip;
  final String trackName;
  final int bpm;
  final ValueChanged<ProjectSnapshot> onSnapshot;
  final double savedArrangementPlayhead;

  /// GM drum pitch for this track (38 snare, 36 kick, …). Locks draw lane + scroll.
  final int? drumAnchorPitch;
  final MidiLaneLayout? drumLaneLayout;

  @override
  State<PianoRollScreen> createState() => _PianoRollScreenState();
}

class _PianoRollScreenState extends State<PianoRollScreen>
    with TickerProviderStateMixin {
  late List<MidiNoteSnapshot> _notes;
  late List<MidiClipTakeSnapshot> _takes;
  late int _initialOctaveOffset;
  late double _clipLengthBeats;
  late List<MidiClipTakeRegionSnapshot> _takeRegions;
  late final ClipEditorTransportController _previewTransport;
  late final PianoRollNoteAudition _noteAudition;
  final TimelineViewportScrollController _timelineScrollController =
      TimelineViewportScrollController();
  final List<List<MidiNoteSnapshot>> _undoStack = [];
  final List<List<MidiNoteSnapshot>> _redoStack = [];

  PianoRollGridSettings _grid = const PianoRollGridSettings();
  late PianoRollScaleSettings _scale;
  PianoRollTool _tool = PianoRollTool.select;
  PianoRollDrawPattern _drawPattern = PianoRollDrawPattern.single;
  late MidiEditorMode _editorMode;
  bool _showTakes = false;
  int? _selectedIndex;
  int? _selectedTakeMarker;
  int _viewRangeBars = EditorViewRange.defaultBars;
  Future<void>? _pendingNoteSave;

  @override
  void initState() {
    super.initState();
    _notes = List.of(widget.clip.notes);
    _takes = List.of(widget.clip.takes);
    _takeRegions = List.of(widget.clip.activeTakeRegions);
    _editorMode = widget.drumLaneLayout == null
        ? MidiEditorMode.piano
        : MidiEditorMode.drums;
    _scale = PianoRollScaleSettings.fromClip(widget.clip);
    _clipLengthBeats = widget.clip.editorContentLengthBeats;
    _previewTransport = ClipEditorTransportController(
      bridge: widget.bridge,
      clipStartBeat: widget.clip.startBeat,
      savedArrangementPlayhead: widget.savedArrangementPlayhead,
      vsync: this,
      maxClipBeat: _clipLengthBeats,
    );
    _previewTransport.addListener(_onPreviewTransportChanged);
    _noteAudition = PianoRollNoteAudition(
      bridge: widget.bridge,
      bpm: widget.bpm,
      drumAnchorPitch: widget.drumAnchorPitch,
    );
    _initialOctaveOffset = widget.drumAnchorPitch != null
        ? PianoRollMetrics.octaveOffsetFromPitch(widget.drumAnchorPitch!)
        : PianoRollMetrics.initialOctaveOffset(
            _notes.map((n) => n.pitch),
          );
    widget.bridge.enterPlayMode();
  }

  void _onPreviewTransportChanged() {
    if (mounted) setState(() {});
  }

  bool _previewTransportCommandInFlight = false;

  Future<void> _startPreviewPlay() async {
    if (_previewTransport.isPlaying || _previewTransportCommandInFlight) return;
    _previewTransportCommandInFlight = true;
    try {
      final beat = _previewTransport.clipLocalBeat;
      await _previewTransport.play(bpm: widget.bpm);
      if (mounted) {
        _timelineScrollController.revealPlayheadAtViewportOrigin(beat);
      }
    } finally {
      _previewTransportCommandInFlight = false;
    }
  }

  Future<void> _stopPreviewPlay() async {
    if (!_previewTransport.isPlaying || _previewTransportCommandInFlight) {
      return;
    }
    _previewTransportCommandInFlight = true;
    try {
      await _previewTransport.stop();
    } finally {
      _previewTransportCommandInFlight = false;
    }
  }

  Future<void> _togglePreviewPlay() async {
    if (_previewTransport.isPlaying) {
      await _stopPreviewPlay();
    } else {
      await _startPreviewPlay();
    }
  }

  @override
  void didUpdateWidget(PianoRollScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSpan = widget.clip.editorContentLengthBeats;
    if (nextSpan != oldWidget.clip.editorContentLengthBeats &&
        (nextSpan - _clipLengthBeats).abs() > 0.001) {
      setState(() {
        _clipLengthBeats = nextSpan;
        _previewTransport.maxClipBeat = nextSpan;
      });
    }
    if (widget.clip.takes != oldWidget.clip.takes ||
        widget.clip.activeTakeRegions != oldWidget.clip.activeTakeRegions) {
      _takes = List.of(widget.clip.takes);
      _takeRegions = List.of(widget.clip.activeTakeRegions);
    }
  }

  @override
  void dispose() {
    _previewTransport.removeListener(_onPreviewTransportChanged);
    unawaited(_previewTransport.disposePreview());
    unawaited(_noteAudition.release());
    widget.bridge.allNotesOff();
    super.dispose();
  }

  double get _virtualLengthBeats {
    var contentEnd = _clipLengthBeats;
    for (final note in _notes) {
      contentEnd = math.max(contentEnd, note.startBeat + note.durationBeats);
    }
    return PianoRollMetrics.virtualLengthBeats(contentEnd);
  }

  String get _gridDockLabel {
    final base = _grid.snap.shortLabel;
    final snap = _grid.triplet ? '${base}T' : base;
    return _scale.snapToScale ? '$snap · ${_scale.rootLabel}' : snap;
  }

  void _pushUndo() {
    _undoStack.add(_cloneNotes(_notes));
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  List<MidiNoteSnapshot> _cloneNotes(List<MidiNoteSnapshot> notes) {
    return notes
        .map(
          (n) => MidiNoteSnapshot(
            pitch: n.pitch,
            startBeat: n.startBeat,
            durationBeats: n.durationBeats,
            velocity: n.velocity,
          ),
        )
        .toList();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_cloneNotes(_notes));
    setState(() => _notes = _undoStack.removeLast());
    _queueNoteSave();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_cloneNotes(_notes));
    setState(() => _notes = _redoStack.removeLast());
    _queueNoteSave();
  }

  void _onNotesChanged(List<MidiNoteSnapshot> notes) {
    setState(() => _notes = notes);
  }

  void _onEditStarted() {
    setState(_pushUndo);
  }

  void _onEditFinished() {
    _queueNoteSave();
  }

  void _applyNotes(List<MidiNoteSnapshot> notes, {int? selectedIndex}) {
    setState(() {
      _pushUndo();
      _notes = notes;
      _selectedIndex = selectedIndex;
    });
    _queueNoteSave();
  }

  void _queueNoteSave() {
    _pendingNoteSave = _persistNotes();
  }

  Future<void> _closeEditor() async {
    final pending = _pendingNoteSave;
    if (pending != null) {
      await pending;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _quantizeSelection() {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _notes.length) return;
    final notes = List<MidiNoteSnapshot>.of(_notes);
    notes[index] = PianoRollNoteOps.quantize(
      notes[index],
      _grid,
      maxLengthBeats: _clipLengthBeats,
    );
    _applyNotes(notes, selectedIndex: index);
  }

  void _quantizeAll() {
    final notes = PianoRollNoteOps.quantizeAll(
      _notes,
      _grid,
      maxLengthBeats: _clipLengthBeats,
    );
    _applyNotes(notes, selectedIndex: _selectedIndex);
  }

  void _nudgeSelected({double beatDelta = 0, int pitchDelta = 0}) {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _notes.length) return;
    final notes = List<MidiNoteSnapshot>.of(_notes);
    final nudged = PianoRollNoteOps.nudge(
      notes[index],
      beatDelta: beatDelta,
      pitchDelta: pitchDelta,
      snapBeats: _grid.snapBeats,
      maxLengthBeats: _clipLengthBeats,
      minPitch: PianoRollMetrics.gridMinPitch,
      maxPitch: PianoRollMetrics.gridMaxPitch,
    );
    notes[index] = MidiNoteSnapshot(
      pitch: _scale.snapPitch(
        nudged.pitch,
        minPitch: PianoRollMetrics.gridMinPitch,
        maxPitch: PianoRollMetrics.gridMaxPitch,
      ),
      startBeat: nudged.startBeat,
      durationBeats: nudged.durationBeats,
      velocity: nudged.velocity,
    );
    _applyNotes(notes, selectedIndex: index);
  }

  void _deleteSelected() {
    final index = _selectedIndex;
    if (index == null || index < 0 || index >= _notes.length) return;
    final notes = List<MidiNoteSnapshot>.of(_notes)..removeAt(index);
    _applyNotes(notes, selectedIndex: null);
  }

  Future<void> _persistClipLength() async {
    try {
      final snapshot = await widget.bridge.setClipLength(
        clipId: widget.clip.id,
        lengthBeats: _clipLengthBeats,
        target: ClipLengthTarget.content,
      );
      widget.onSnapshot(snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update clip length — try again'),
            backgroundColor: PianoRollTheme.saveError,
          ),
        );
      }
    }
  }

  Future<void> _persistNotes() async {
    try {
      final notes = widget.drumAnchorPitch != null
          ? _notes
              .map(
                (n) => MidiNoteSnapshot(
                  pitch: widget.drumAnchorPitch!,
                  startBeat: n.startBeat,
                  durationBeats: n.durationBeats,
                  velocity: n.velocity,
                ),
              )
              .toList()
          : _notes;
      final snapshot = await widget.bridge.setMidiClipNotes(
        clipId: widget.clip.id,
        notes: notes,
      );
      widget.onSnapshot(snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save notes — try again'),
            backgroundColor: PianoRollTheme.saveError,
          ),
        );
      }
    }
  }

  List<double> get _takeMarkerBeats =>
      _takeRegions.skip(1).map((region) => region.startBeat).toList();

  MidiClipSnapshot? _findClipInSnapshot(ProjectSnapshot snapshot, String id) {
    for (final track in snapshot.tracks) {
      for (final clip in track.midiClips) {
        if (clip.id == id) return clip;
      }
    }
    return null;
  }

  void _applyRefreshedClip(MidiClipSnapshot clip) {
    setState(() {
      _notes = List.of(clip.notes);
      _takes = List.of(clip.takes);
      _takeRegions = List.of(clip.activeTakeRegions);
      _clipLengthBeats = clip.editorContentLengthBeats;
      _selectedIndex = null;
    });
    _previewTransport.maxClipBeat = _clipLengthBeats;
  }

  Future<void> _withMidiTakeSnapshot(
    Future<ProjectSnapshot> Function() action,
  ) async {
    final snapshot = await action();
    widget.onSnapshot(snapshot);
    if (!mounted) return;
    final refreshed = _findClipInSnapshot(snapshot, widget.clip.id);
    if (refreshed != null) {
      _applyRefreshedClip(refreshed);
    }
  }

  Future<void> _setMidiTakeAtPlayhead(String takeId) async {
    final beat = _previewTransport.clipLocalBeat.clamp(0.0, _clipLengthBeats);
    await _withMidiTakeSnapshot(
      () => widget.bridge.setMidiClipTakeAtBeat(
        clipId: widget.clip.id,
        beat: beat,
        takeId: takeId,
      ),
    );
  }

  Future<void> _splitMidiTakeAtPlayhead() async {
    final beat = _previewTransport.clipLocalBeat.clamp(0.0, _clipLengthBeats);
    await _withMidiTakeSnapshot(
      () => widget.bridge.splitMidiClipTakeRegionAtBeat(
        clipId: widget.clip.id,
        beat: beat,
      ),
    );
    if (!mounted) return;
    setState(() {
      _selectedTakeMarker = _takeMarkerBeats.indexWhere(
        (marker) => (marker - beat).abs() < .01,
      );
      if (_selectedTakeMarker == -1) _selectedTakeMarker = null;
    });
  }

  Future<void> _deleteSelectedMidiTakeMarker() async {
    final index = _selectedTakeMarker;
    if (index == null || index < 0 || index >= _takeMarkerBeats.length) {
      return;
    }
    await _withMidiTakeSnapshot(
      () => widget.bridge.deleteMidiClipTakeMarker(
        clipId: widget.clip.id,
        markerIndex: index,
      ),
    );
    if (mounted) setState(() => _selectedTakeMarker = null);
  }

  Future<void> _nudgeSelectedMidiTakeMarker(int direction) async {
    final index = _selectedTakeMarker;
    final markers = _takeMarkerBeats;
    if (index == null || index < 0 || index >= markers.length) return;
    final step = math.max(0.125, _grid.snapBeats);
    final next = markers[index] + direction * step;
    await _withMidiTakeSnapshot(
      () => widget.bridge.moveMidiClipTakeMarker(
        clipId: widget.clip.id,
        markerIndex: index,
        beat: next,
      ),
    );
    if (mounted) setState(() => _selectedTakeMarker = index);
  }

  void _openGridSheet() {
    PianoRollGridSheet.show(
      context,
      settings: _grid,
      scaleSettings: _scale,
      onChanged: (next) => setState(() {
        _grid = _editorMode == MidiEditorMode.drums && next.snapBeats > 0
            ? next.copyWith(defaultNoteBeats: next.snapBeats)
            : next;
      }),
      onScaleChanged: _onScaleChanged,
      showScaleControls: _editorMode == MidiEditorMode.piano,
      bottomInset:
          PianoRollMetrics.toolDockHeight + PlayDeckLayout.chromeHeight,
    );
  }

  void _openDrawSheet() {
    PianoRollGridSheet.showDraw(
      context,
      settings: _grid,
      scaleSettings: _scale,
      onChanged: (next) => setState(() => _grid = next),
      onScaleChanged: _onScaleChanged,
      showScaleControls: _editorMode == MidiEditorMode.piano,
      drawPattern: _drawPattern,
      onDrawPatternChanged: (value) => setState(() => _drawPattern = value),
      bottomInset:
          PianoRollMetrics.toolDockHeight + PlayDeckLayout.chromeHeight,
    );
  }

  void _onScaleChanged(PianoRollScaleSettings next) {
    if (next == _scale) return;
    setState(() => _scale = next);
    unawaited(_persistScaleSettings(next));
  }

  Future<void> _persistScaleSettings(PianoRollScaleSettings settings) async {
    try {
      await widget.bridge.setMidiClipEditorScale(
        clipId: widget.clip.id,
        rootPitchClass: settings.rootPitchClass,
        scaleId: settings.scale.id,
        highlight: settings.highlight,
        snapToScale: settings.snapToScale,
        chordQuality: settings.chordQuality.name,
      );
    } catch (_) {
      // Editor metadata is non-audio-critical; keep local state if bridge save fails.
    }
  }

  void _openEditSheet() {
    PianoRollEditSheet.show(
      context,
      hasSelection: _selectedIndex != null,
      noteCount: _notes.length,
      onQuantizeSelection: _quantizeSelection,
      onQuantizeAll: _quantizeAll,
      onNudgeLeft: () => _nudgeSelected(beatDelta: -1),
      onNudgeRight: () => _nudgeSelected(beatDelta: 1),
      onNudgeUp: () => _nudgeSelected(pitchDelta: 1),
      onNudgeDown: () => _nudgeSelected(pitchDelta: -1),
      onDeleteSelected: _deleteSelected,
      bottomInset:
          PianoRollMetrics.toolDockHeight + PlayDeckLayout.chromeHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final barCount = (_clipLengthBeats / PianoRollMetrics.beatsPerBar).ceil();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _closeEditor();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: PianoRollTheme.background,
        appBar: AppBar(
          backgroundColor: PianoRollTheme.background,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeEditor,
          ),
          title: Text(
            '${widget.trackName} · $barCount bars',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          actions: [
            if (_takes.isNotEmpty)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor:
                      _showTakes ? const Color(0xFFFF6D8A) : Colors.white70,
                ),
                icon: Icon(
                  _showTakes ? Icons.splitscreen : Icons.splitscreen_outlined,
                  size: 18,
                ),
                label: const Text('TAKES'),
                onPressed: () => setState(() => _showTakes = !_showTakes),
              ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              icon: const Icon(Icons.grid_4x4, size: 18),
              label: Text(_gridDockLabel),
              onPressed: _openGridSheet,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: EditorViewRangeDropdown(
                  value: _viewRangeBars,
                  onChanged: (bars) => setState(() => _viewRangeBars = bars),
                ),
              ),
            ),
          ],
        ),
        body: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: Column(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: _previewTransport,
                  builder: (context, _) => PianoRollViewport(
                    timelineScrollController: _timelineScrollController,
                    notes: _notes,
                    clipLengthBeats: _clipLengthBeats,
                    virtualLengthBeats: _virtualLengthBeats,
                    minPitch: PianoRollMetrics.gridMinPitch,
                    maxPitch: PianoRollMetrics.gridMaxPitch,
                    drumAnchorPitch: widget.drumAnchorPitch,
                    laneLayout: _editorMode == MidiEditorMode.drums
                        ? widget.drumLaneLayout
                        : null,
                    gridSettings: _grid,
                    scaleSettings: _scale,
                    tool: _tool,
                    drawPattern: _drawPattern,
                    selectedIndex: _selectedIndex,
                    onNotesChanged: _onNotesChanged,
                    onSelectionChanged: (index) =>
                        setState(() => _selectedIndex = index),
                    onEditStarted: _onEditStarted,
                    onEditFinished: _onEditFinished,
                    onClipLengthChanged: (length) {
                      setState(() => _clipLengthBeats = length);
                      _previewTransport.maxClipBeat = length;
                    },
                    onClipLengthCommit: _persistClipLength,
                    viewRangeBars: _viewRangeBars,
                    virtualPlayheadBeat: _previewTransport.clipLocalBeat,
                    onVirtualPlayheadSeek: _previewTransport.seekClipLocal,
                    previewPlaying: _previewTransport.isPlaying,
                    onPreviewPlayRequested: _startPreviewPlay,
                    onPreviewStopRequested: _stopPreviewPlay,
                    onNotePreview: (note, {hold = false}) {
                      unawaited(_noteAudition.preview(note, hold: hold));
                    },
                    onNotePreviewEnd: () {
                      unawaited(_noteAudition.release());
                    },
                    onPitchPreview: (pitch) {
                      unawaited(
                        _noteAudition.preview(
                          MidiNoteSnapshot(
                            pitch: pitch,
                            startBeat: 0,
                            durationBeats: 0.25,
                            velocity: 100,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              PianoRollToolDock(
                tool: _tool,
                canUndo: _undoStack.isNotEmpty,
                canRedo: _redoStack.isNotEmpty,
                previewPlaying: _previewTransport.isPlaying,
                onPreviewPlayStop: _togglePreviewPlay,
                onToolChanged: (tool) => setState(() => _tool = tool),
                onEditTap: _openEditSheet,
                onUndo: _undo,
                onRedo: _redo,
                editorMode: _editorMode,
                canUseDrumMode: widget.drumLaneLayout != null,
                onEditorModeChanged: (mode) => setState(() {
                  _editorMode = mode;
                  _selectedIndex = null;
                }),
                onDrawSettings: _openDrawSheet,
              ),
              if (_showTakes && _takes.isNotEmpty)
                _MidiTakeLaneStack(
                  takes: _takes,
                  regions: _takeRegions,
                  clipLengthBeats: _clipLengthBeats,
                  playheadBeat: _previewTransport.clipLocalBeat,
                  selectedMarker: _selectedTakeMarker,
                  onMarkerSelected: (index) =>
                      setState(() => _selectedTakeMarker = index),
                  onTakeTap: _setMidiTakeAtPlayhead,
                  onSplit: _splitMidiTakeAtPlayhead,
                  onDeleteMarker: _deleteSelectedMidiTakeMarker,
                  onNudgeMarker: _nudgeSelectedMidiTakeMarker,
                ),
              PlayDeck(
                bridge: widget.bridge,
                initialSurfaceMode: PlaySurfaceMode.keys,
                initialOctaveOffset: _initialOctaveOffset,
                padPitchBase: widget.drumAnchorPitch,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MidiTakeLaneStack extends StatelessWidget {
  const _MidiTakeLaneStack({
    required this.takes,
    required this.regions,
    required this.clipLengthBeats,
    required this.playheadBeat,
    required this.selectedMarker,
    required this.onMarkerSelected,
    required this.onTakeTap,
    required this.onSplit,
    required this.onDeleteMarker,
    required this.onNudgeMarker,
  });

  final List<MidiClipTakeSnapshot> takes;
  final List<MidiClipTakeRegionSnapshot> regions;
  final double clipLengthBeats;
  final double playheadBeat;
  final int? selectedMarker;
  final ValueChanged<int> onMarkerSelected;
  final ValueChanged<String> onTakeTap;
  final VoidCallback onSplit;
  final VoidCallback onDeleteMarker;
  final ValueChanged<int> onNudgeMarker;

  @override
  Widget build(BuildContext context) {
    final activeTakeIds = regions.map((r) => r.takeId).toSet();
    return Container(
      height: 156,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: PianoRollTheme.background,
        border: Border(top: BorderSide(color: Color(0xFF2D3038))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MIDI TAKES',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                _TakeActionButton(
                  label: 'SPLIT',
                  icon: Icons.call_split,
                  onTap: onSplit,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniCompButton(
                      icon: Icons.chevron_left,
                      onTap: selectedMarker == null
                          ? null
                          : () => onNudgeMarker(-1),
                    ),
                    const SizedBox(width: 6),
                    _MiniCompButton(
                      icon: Icons.chevron_right,
                      onTap: selectedMarker == null
                          ? null
                          : () => onNudgeMarker(1),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _TakeActionButton(
                  label: 'DELETE',
                  icon: Icons.delete_outline,
                  onTap: selectedMarker == null ? null : onDeleteMarker,
                ),
                const Spacer(),
                Text(
                  selectedMarker == null ? 'tap marker' : 'marker selected',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final width = math.max(1.0, box.maxWidth);
                final length = math.max(0.25, clipLengthBeats);
                return Stack(
                  children: [
                    CustomPaint(
                      painter: _MidiTakeGridPainter(
                        rowCount: takes.length,
                        lengthBeats: length,
                      ),
                      child: const SizedBox.expand(),
                    ),
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: takes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (context, index) {
                        final take = takes[index];
                        final active = activeTakeIds.contains(take.id);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTakeTap(take.id),
                          child: _MidiTakeLane(
                            take: take,
                            width: width,
                            lengthBeats: length,
                            active: active,
                            rowIndex: index,
                          ),
                        );
                      },
                    ),
                    for (final entry in regions.skip(1).indexed)
                      Positioned(
                        left: (entry.$2.startBeat / length) * width - 8,
                        top: 0,
                        bottom: 0,
                        width: 16,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onMarkerSelected(entry.$1),
                          child: Center(
                            child: Container(
                              width: selectedMarker == entry.$1 ? 3 : 2,
                              color: selectedMarker == entry.$1
                                  ? Colors.white
                                  : const Color(0xFFFF6D8A),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: (playheadBeat.clamp(0.0, length) / length) * width,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 1, color: Colors.white54),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MidiTakeLane extends StatelessWidget {
  const _MidiTakeLane({
    required this.take,
    required this.width,
    required this.lengthBeats,
    required this.active,
    required this.rowIndex,
  });

  final MidiClipTakeSnapshot take;
  final double width;
  final double lengthBeats;
  final bool active;
  final int rowIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        children: [
          if (active)
            Positioned.fill(
              child: ColoredBox(
                color: const Color(0xFFFF6D8A).withValues(alpha: 0.10),
              ),
            ),
          Positioned(
            left: 8,
            top: 5,
            child: Text(
              take.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final note in take.notes)
            Positioned(
              left: (note.startBeat / lengthBeats) * width,
              width: math.max(2.0, note.durationBeats / lengthBeats * width),
              top: 20,
              height: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFFD1DC)
                      : const Color(0xFF7F8799),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MidiTakeGridPainter extends CustomPainter {
  const _MidiTakeGridPainter({
    required this.rowCount,
    required this.lengthBeats,
  });

  final int rowCount;
  final double lengthBeats;

  @override
  void paint(Canvas canvas, Size size) {
    final rowPaint = Paint()..color = const Color(0xFF2B2E36);
    final beatPaint = Paint()..color = const Color(0x223F4656);
    final barPaint = Paint()..color = const Color(0x334F5668);
    const rowHeight = 32.0;
    for (var i = 0; i <= rowCount; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rowPaint);
    }
    final beats = lengthBeats.ceil();
    for (var beat = 0; beat <= beats; beat++) {
      final x = beat / lengthBeats * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        beat % 4 == 0 ? barPaint : beatPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MidiTakeGridPainter oldDelegate) =>
      oldDelegate.rowCount != rowCount ||
      oldDelegate.lengthBeats != lengthBeats;
}

class _TakeActionButton extends StatelessWidget {
  const _TakeActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? const Color(0xFF23242A) : const Color(0xFF2C2F38),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: onTap == null ? Colors.white24 : Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: onTap == null ? Colors.white24 : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCompButton extends StatelessWidget {
  const _MiniCompButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color:
            onTap == null ? const Color(0xFF23242A) : const Color(0xFF2C2F38),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            color: onTap == null ? Colors.white24 : Colors.white70,
            size: 18,
          ),
        ),
      ),
    );
  }
}
