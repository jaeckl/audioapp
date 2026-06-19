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
import 'piano_roll_metrics.dart';
import 'piano_roll_note_audition.dart';
import 'piano_roll_note_ops.dart';
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
  });

  final EngineBridge bridge;
  final MidiClipSnapshot clip;
  final String trackName;
  final int bpm;
  final ValueChanged<ProjectSnapshot> onSnapshot;
  final double savedArrangementPlayhead;
  /// GM drum pitch for this track (38 snare, 36 kick, …). Locks draw lane + scroll.
  final int? drumAnchorPitch;

  @override
  State<PianoRollScreen> createState() => _PianoRollScreenState();
}

class _PianoRollScreenState extends State<PianoRollScreen> with TickerProviderStateMixin {
  late List<MidiNoteSnapshot> _notes;
  late int _initialOctaveOffset;
  late double _clipLengthBeats;
  late final ClipEditorTransportController _previewTransport;
  late final PianoRollNoteAudition _noteAudition;
  final TimelineViewportScrollController _timelineScrollController =
      TimelineViewportScrollController();
  final List<List<MidiNoteSnapshot>> _undoStack = [];
  final List<List<MidiNoteSnapshot>> _redoStack = [];

  PianoRollGridSettings _grid = const PianoRollGridSettings();
  PianoRollTool _tool = PianoRollTool.select;
  int? _selectedIndex;
  int _viewRangeBars = EditorViewRange.defaultBars;

  @override
  void initState() {
    super.initState();
    _notes = List.of(widget.clip.notes);
    _clipLengthBeats = widget.clip.lengthBeats;
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
    if (!_previewTransport.isPlaying || _previewTransportCommandInFlight) return;
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
    return _grid.triplet ? '${base}T' : base;
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
    _persistNotes();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_cloneNotes(_notes));
    setState(() => _notes = _redoStack.removeLast());
    _persistNotes();
  }

  void _onNotesChanged(List<MidiNoteSnapshot> notes) {
    setState(() => _notes = notes);
  }

  void _onEditStarted() {
    setState(_pushUndo);
  }

  void _onEditFinished() {
    _persistNotes();
  }

  void _applyNotes(List<MidiNoteSnapshot> notes, {int? selectedIndex}) {
    setState(() {
      _pushUndo();
      _notes = notes;
      _selectedIndex = selectedIndex;
    });
    _persistNotes();
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
    notes[index] = PianoRollNoteOps.nudge(
      notes[index],
      beatDelta: beatDelta,
      pitchDelta: pitchDelta,
      snapBeats: _grid.snapBeats,
      maxLengthBeats: _clipLengthBeats,
      minPitch: PianoRollMetrics.gridMinPitch,
      maxPitch: PianoRollMetrics.gridMaxPitch,
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

  void _openGridSheet() {
    PianoRollGridSheet.show(
      context,
      settings: _grid,
      onChanged: (next) => setState(() => _grid = next),
      bottomInset: PianoRollMetrics.toolDockHeight + PlayDeckLayout.chromeHeight,
    );
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
      bottomInset: PianoRollMetrics.toolDockHeight + PlayDeckLayout.chromeHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final barCount = (widget.clip.lengthBeats / PianoRollMetrics.beatsPerBar).ceil();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: PianoRollTheme.background,
      appBar: AppBar(
        backgroundColor: PianoRollTheme.background,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.trackName} · $barCount bars',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
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
                  gridSettings: _grid,
                  tool: _tool,
                  selectedIndex: _selectedIndex,
                  onNotesChanged: _onNotesChanged,
                  onSelectionChanged: (index) => setState(() => _selectedIndex = index),
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
                ),
              ),
            ),
            PianoRollToolDock(
              tool: _tool,
              gridLabel: _gridDockLabel,
              canUndo: _undoStack.isNotEmpty,
              canRedo: _redoStack.isNotEmpty,
              previewPlaying: _previewTransport.isPlaying,
              onPreviewPlayStop: _togglePreviewPlay,
              onToolChanged: (tool) => setState(() => _tool = tool),
              onGridTap: _openGridSheet,
              onEditTap: _openEditSheet,
              onUndo: _undo,
              onRedo: _redo,
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
    );
  }
}
