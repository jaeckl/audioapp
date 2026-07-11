part of 'automation_editor_screen.dart';

class _AutomationEditorScreenState extends State<AutomationEditorScreen>
    with TickerProviderStateMixin {
  late List<AutomationPointSnapshot> _points;
  late double _clipLengthBeats;
  late final ClipEditorTransportController _previewTransport;
  final List<List<AutomationPointSnapshot>> _undoStack = [];
  final List<List<AutomationPointSnapshot>> _redoStack = [];

  PianoRollGridSettings _grid = const PianoRollGridSettings();
  AutomationEditorTool _tool = AutomationEditorTool.select;
  final Set<int> _selectedIndices = {};
  final Set<int> _deleteMarkedIndices = {};
  int _viewRangeBars = EditorViewRange.defaultBars;
  final TimelineViewportScrollController _timelineScrollController =
      TimelineViewportScrollController();

  bool _insertPanelOpen = false;
  AutomationCurveShape? _activeShape;
  AutomationShapeParams _shapeParams = const AutomationShapeParams();
  double? _insertStartBeat;
  double? _insertEndBeat;
  double? _insertStartValue;
  double? _insertEndValue;

  @override
  void initState() {
    super.initState();
    _points = _initialPoints(widget.clip);
    _clipLengthBeats = widget.clip.editorContentLengthBeats;
    _previewTransport = ClipEditorTransportController(
      bridge: widget.bridge,
      clipStartBeat: widget.clip.startBeat,
      savedArrangementPlayhead: widget.savedArrangementPlayhead,
      vsync: this,
      maxClipBeat: _clipLengthBeats,
    );
    _previewTransport.addListener(_onPreviewTransportChanged);
    unawaited(widget.bridge.enterPlayMode());
  }

  bool _previewTransportCommandInFlight = false;

  @override
  void didUpdateWidget(AutomationEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSpan = widget.clip.editorContentLengthBeats;
    if (nextSpan != oldWidget.clip.editorContentLengthBeats &&
        (nextSpan - _clipLengthBeats).abs() > 0.001) {
      setState(() {
        _clipLengthBeats = nextSpan;
        _previewTransport.maxClipBeat = nextSpan;
      });
    }
  }

  @override
  void dispose() {
    _previewTransport.removeListener(_onPreviewTransportChanged);
    unawaited(_previewTransport.disposePreview());
    super.dispose();
  }

  double get _virtualLengthBeats {
    var contentEnd = _clipLengthBeats;
    for (final point in _points) {
      contentEnd = math.max(contentEnd, point.beat);
    }
    return AutomationEditorMetrics.virtualLengthBeats(contentEnd);
  }

  String get _gridDockLabel {
    final base = _grid.snap.shortLabel;
    return _grid.triplet ? '${base}T' : base;
  }

  String get _title {
    final link = widget.clip.isLinked ? widget.clip.linkLabel : 'Automation';
    final bars = (_clipLengthBeats / PianoRollMetrics.beatsPerBar).ceil();
    return '${widget.trackName} · $link · $bars bars';
  }

  void _onEditStarted() => setState(_pushUndo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AutomationEditorTheme.background,
      appBar: AppBar(
        backgroundColor: AutomationEditorTheme.background,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Load curve',
            onPressed: _loadCurveResource,
            icon: const Icon(Icons.folder_open_outlined),
          ),
          IconButton(
            tooltip: 'Save curve',
            onPressed: _saveCurveResource,
            icon: const Icon(Icons.bookmark_add_outlined),
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
            AutomationEditorToolDock(
              tool: _tool,
              canUndo: _undoStack.isNotEmpty,
              canRedo: _redoStack.isNotEmpty,
              canInsert: _selectedIndices.length == 2 && !_insertPanelOpen,
              canDeleteMarked: _deleteMarkedIndices.isNotEmpty,
              previewPlaying: _previewTransport.isPlaying,
              onPreviewPlayStop: _togglePreviewPlay,
              activeShape: _activeShape,
              onShapeSelected: _selectShapeTool,
              onToolChanged: _onToolChanged,
              onInsertTap: _openInsertPanel,
              onDeleteMarkedTap: _deleteMarkedNodes,
              onUndo: _undo,
              onRedo: _redo,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _previewTransport,
                builder: (context, _) => AutomationEditorViewport(
                  timelineScrollController: _timelineScrollController,
                  points: _points,
                  clipLengthBeats: _clipLengthBeats,
                  virtualLengthBeats: _virtualLengthBeats,
                  gridSettings: _grid,
                  tool: _tool,
                  paintShape: _activeShape,
                  selectedIndices: _selectedIndices,
                  deleteMarkedIndices: _deleteMarkedIndices,
                  insertHighlightStartBeat:
                      _insertPanelOpen ? _insertStartBeat : null,
                  insertHighlightEndBeat:
                      _insertPanelOpen ? _insertEndBeat : null,
                  onPointsChanged: _onPointsChanged,
                  onToggleSelect: _toggleSelect,
                  onToggleDeleteMark: _toggleDeleteMark,
                  onClearSelection: () => setState(_selectedIndices.clear),
                  onEditStarted: _onEditStarted,
                  onEditFinished: _persistPoints,
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
                ),
              ),
            ),
            if (_insertPanelOpen)
              AutomationShapePanel(
                activeShape: _activeShape,
                params: _shapeParams,
                onShapeSelected: _applyShape,
                onParamsChanged: _onShapeParamsChanged,
                onClose: () => _closeInsertPanel(),
              ),
          ],
        ),
      ),
    );
  }
}
