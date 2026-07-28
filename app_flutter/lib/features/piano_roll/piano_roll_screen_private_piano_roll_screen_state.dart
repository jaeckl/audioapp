part of 'piano_roll_screen.dart';

class _PianoRollScreenState extends State<PianoRollScreen> with TickerProviderStateMixin {
  late List<MidiNoteSnapshot> _notes;
  late List<MidiClipTakeSnapshot> _takes;
  late int _initialOctaveOffset;
  late double _clipLengthBeats;
  late List<MidiClipTakeRegionSnapshot> _takeRegions;
  late final ClipEditorTransportController _previewTransport;
  late final PianoRollNoteAudition _noteAudition;
  final TimelineViewportScrollController _timelineScrollController = TimelineViewportScrollController();
  final List<List<MidiNoteSnapshot>> _undoStack = [];
  final List<List<MidiNoteSnapshot>> _redoStack = [];
  final GlobalKey<PlayDeckState> _playDeckKey = GlobalKey<PlayDeckState>();

  PianoRollGridSettings _grid = const PianoRollGridSettings();
  late PianoRollScaleSettings _scale;
  PianoRollTool _tool = PianoRollTool.select;
  PianoRollDrawPattern _drawPattern = PianoRollDrawPattern.single;
  late MidiEditorMode _editorMode;
  bool _showTakes = false;
  PianoRollCenterMode _toolMode = PianoRollCenterMode.notes;
  late HarmonicToolParams _harmonicParams;
  int _armedDegree = 1;
  RhythmGenre _progressionGenre = RhythmGenre.pop;
  String _progressionSubgenreId = 'pop_radio';
  String _progressionTemplateId = ProgressionTemplate.pop1564.id;
  RhythmGenre _rhythmGenre = RhythmGenre.house;
  String _rhythmSubgenreId = 'house_classic';
  String _rhythmPresetId = 'house_offbeat_ands';
  int _drumHits = 4;
  int _drumSteps = 16;
  int _drumRotate = 0;
  double _drumStepBeats = 0.25;
  double _drumProbability = 0.7;
  int _drumRatchet = 4;
  double _drumHumanize = 12;
  double _drumFillLengthBeats = 4;
  double _drumFillIntensity = 0.65;
  String _drumFillStyle = 'roll';
  int? _selectedDrumPitch;
  List<ChordSlot> _chordSlots = [];
  late bool _compFlattened;
  MidiCompTool _compTool = MidiCompTool.comp;
  bool _autoFlattenNotified = false;
  Future<void>? _flattenInFlight;
  int? _selectedIndex;
  bool _harmonyChordSelected = true;
  int? _selectedTakeMarker;
  int _viewRangeBars = EditorViewRange.defaultBars;
  Future<void>? _pendingNoteSave;

  @override
  void initState() {
    super.initState();
    _notes = List.of(widget.clip.notes);
    _takes = List.of(widget.clip.takes);
    _takeRegions = List.of(widget.clip.activeTakeRegions);
    _compFlattened = widget.clip.compFlattened;
    _editorMode = widget.drumLaneLayout == null ? MidiEditorMode.piano : MidiEditorMode.drums;
    _selectedDrumPitch = _initialDrumPitch();
    _scale = PianoRollScaleSettings.fromClip(widget.clip);
    _harmonicParams = HarmonicToolParams();
    _chordSlots = HarmonicNoteOps.slotsFromNotes(_notes);
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

  bool _previewTransportCommandInFlight = false;

  @override
  void didUpdateWidget(PianoRollScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSpan = widget.clip.editorContentLengthBeats;
    if (nextSpan != oldWidget.clip.editorContentLengthBeats && (nextSpan - _clipLengthBeats).abs() > 0.001) {
      setState(() {
        _clipLengthBeats = nextSpan;
        _previewTransport.maxClipBeat = nextSpan;
      });
    }
    if (widget.clip.takes != oldWidget.clip.takes || widget.clip.activeTakeRegions != oldWidget.clip.activeTakeRegions) {
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

  String get _snapChipLabel {
    final base = _grid.snap.shortLabel;
    return _grid.triplet ? '${base}T' : base;
  }

  String? get _scaleChipLabel {
    if (_editorMode != MidiEditorMode.piano) return null;
    final scale = _scale.scale.label;
    return '${_scale.rootLabel} $scale';
  }

  String? get _modeChip {
    if (_takes.length <= 1) return null;
    return _compFlattened ? 'EDIT' : 'COMP';
  }

  bool get _needsCompFlatten => !_compFlattened && _takes.length > 1;

  List<double> get _takeMarkerBeats => _takeRegions.skip(1).map((region) => region.startBeat).toList();

  double? get _selectedTakeMarkerBeat {
    final index = _selectedTakeMarker;
    final markers = _takeMarkerBeats;
    if (index == null || index < 0 || index >= markers.length) return null;
    return markers[index];
  }

  bool? get _selectedTakeMarkerHold {
    final index = _selectedTakeMarker;
    if (index == null || index < 0 || index + 1 >= _takeRegions.length) {
      return null;
    }
    return _takeRegions[index + 1].holdPrevious;
  }

  @override
  Widget build(BuildContext context) => _buildContent(context);

}
