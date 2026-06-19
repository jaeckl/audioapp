import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';
import '../piano_roll/piano_roll_grid_sheet.dart';
import '../piano_roll/piano_roll_metrics.dart';
import '../piano_roll/editor_view_range.dart';
import 'automation_curve_shapes.dart';
import 'automation_editor_metrics.dart';
import 'automation_editor_theme.dart';
import 'automation_editor_tool_dock.dart';
import 'automation_editor_viewport.dart';
import 'automation_shape_panel.dart';

/// Full-screen automation clip editor — piano-roll layout with shape panel.
class AutomationEditorScreen extends StatefulWidget {
  const AutomationEditorScreen({
    super.key,
    required this.trackName,
    required this.clip,
    required this.bridge,
    required this.onSaved,
  });

  final String trackName;
  final AutomationClipSnapshot clip;
  final EngineBridge bridge;
  final ValueChanged<ProjectSnapshot> onSaved;

  @override
  State<AutomationEditorScreen> createState() => _AutomationEditorScreenState();
}

class _AutomationEditorScreenState extends State<AutomationEditorScreen> {
  late List<AutomationPointSnapshot> _points;
  late double _clipLengthBeats;
  final List<List<AutomationPointSnapshot>> _undoStack = [];
  final List<List<AutomationPointSnapshot>> _redoStack = [];

  PianoRollGridSettings _grid = const PianoRollGridSettings();
  AutomationEditorTool _tool = AutomationEditorTool.select;
  final Set<int> _selectedIndices = {};
  final Set<int> _deleteMarkedIndices = {};
  int _viewRangeBars = EditorViewRange.defaultBars;

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
    _clipLengthBeats = widget.clip.lengthBeats;
  }

  List<AutomationPointSnapshot> _initialPoints(AutomationClipSnapshot clip) {
    final points = List<AutomationPointSnapshot>.of(clip.points);
    if (points.length < 2) {
      return [
        const AutomationPointSnapshot(beat: 0, value: 1),
        AutomationPointSnapshot(beat: clip.lengthBeats, value: 0.25),
      ];
    }
    return points;
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
    final link = widget.clip.isLinked
        ? widget.clip.linkLabel
        : 'Automation';
    final bars = (_clipLengthBeats / PianoRollMetrics.beatsPerBar).ceil();
    return '${widget.trackName} · $link · $bars bars';
  }

  List<AutomationPointSnapshot> _clonePoints(List<AutomationPointSnapshot> points) {
    return points
        .map((p) => AutomationPointSnapshot(beat: p.beat, value: p.value))
        .toList();
  }

  void _pushUndo() {
    _undoStack.add(_clonePoints(_points));
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_clonePoints(_points));
    setState(() {
      _points = _undoStack.removeLast();
      _clearTransientSelection();
    });
    _persistPoints();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_clonePoints(_points));
    setState(() {
      _points = _redoStack.removeLast();
      _clearTransientSelection();
    });
    _persistPoints();
  }

  void _clearTransientSelection() {
    _selectedIndices.clear();
    _deleteMarkedIndices.clear();
  }

  void _onPointsChanged(List<AutomationPointSnapshot> points) {
    setState(() => _points = points);
  }

  void _onEditFinished() {
    final selectedSnapshots = _selectedIndices.map((i) => _points[i]).toList();
    final markedSnapshots = _deleteMarkedIndices.map((i) => _points[i]).toList();

    setState(() {
      _points = List<AutomationPointSnapshot>.of(_points)
        ..sort((a, b) => a.beat.compareTo(b.beat));
      _selectedIndices
        ..clear()
        ..addAll(_remapIndices(selectedSnapshots, _points));
      _deleteMarkedIndices
        ..clear()
        ..addAll(_remapIndices(markedSnapshots, _points));
    });
    _persistPoints();
  }

  Iterable<int> _remapIndices(
    List<AutomationPointSnapshot> markers,
    List<AutomationPointSnapshot> points,
  ) sync* {
    for (final marker in markers) {
      var index = points.indexWhere(
        (p) =>
            (p.beat - marker.beat).abs() < 1.0e-4 &&
            (p.value - marker.value).abs() < 1.0e-4,
      );
      if (index < 0) {
        index = points.indexWhere((p) => (p.beat - marker.beat).abs() < 1.0e-3);
      }
      if (index >= 0) yield index;
    }
  }

  void _onEditStarted() => setState(_pushUndo);

  void _onToolChanged(AutomationEditorTool tool) {
    setState(() {
      _tool = tool;
      _selectedIndices.clear();
      _deleteMarkedIndices.clear();
      if (tool != AutomationEditorTool.select) {
        _closeInsertPanel(notify: false);
      }
    });
  }

  void _toggleSelect(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else if (_selectedIndices.length >= 2) {
        final oldest = _selectedIndices.toList()..sort();
        _selectedIndices.remove(oldest.first);
        _selectedIndices.add(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _toggleDeleteMark(int index) {
    setState(() {
      if (_deleteMarkedIndices.contains(index)) {
        _deleteMarkedIndices.remove(index);
      } else {
        _deleteMarkedIndices.add(index);
      }
    });
  }

  void _openInsertPanel() {
    if (_selectedIndices.length != 2) return;
    final anchors = _selectedIndices.map((i) => _points[i]).toList()
      ..sort((a, b) => a.beat.compareTo(b.beat));
    setState(() {
      _insertPanelOpen = true;
      _activeShape = null;
      _insertStartBeat = anchors[0].beat;
      _insertEndBeat = anchors[1].beat;
      _insertStartValue = anchors[0].value;
      _insertEndValue = anchors[1].value;
      _shapeParams = AutomationShapeParams(
        min: math.min(anchors[0].value, anchors[1].value),
        max: math.max(anchors[0].value, anchors[1].value),
      );
    });
  }

  void _closeInsertPanel({bool notify = true}) {
    if (!_insertPanelOpen) return;
    setState(() {
      _insertPanelOpen = false;
      _activeShape = null;
      _insertStartBeat = null;
      _insertEndBeat = null;
      _insertStartValue = null;
      _insertEndValue = null;
      _selectedIndices.clear();
    });
  }

  void _applyShape(AutomationCurveShape shape) {
    final startBeat = _insertStartBeat;
    final endBeat = _insertEndBeat;
    final startValue = _insertStartValue;
    final endValue = _insertEndValue;
    if (startBeat == null ||
        endBeat == null ||
        startValue == null ||
        endValue == null) {
      return;
    }

    final isNewShape = _activeShape != shape;
    if (isNewShape) {
      _pushUndo();
    }

    setState(() {
      _activeShape = shape;
      _points = insertAutomationShapeBetween(
        points: _points,
        startBeat: startBeat,
        endBeat: endBeat,
        startValue: startValue,
        endValue: endValue,
        shape: shape,
        params: _shapeParams,
      );
      _selectedIndices.clear();
    });
    _persistPoints();
  }

  void _onShapeParamsChanged(AutomationShapeParams params) {
    final shape = _activeShape;
    final startBeat = _insertStartBeat;
    final endBeat = _insertEndBeat;
    final startValue = _insertStartValue;
    final endValue = _insertEndValue;
    if (shape == null ||
        startBeat == null ||
        endBeat == null ||
        startValue == null ||
        endValue == null) {
      return;
    }

    setState(() {
      _shapeParams = params;
      _points = insertAutomationShapeBetween(
        points: _points,
        startBeat: startBeat,
        endBeat: endBeat,
        startValue: startValue,
        endValue: endValue,
        shape: shape,
        params: _shapeParams,
      );
    });
    _persistPoints();
  }

  void _deleteMarkedNodes() {
    if (_deleteMarkedIndices.isEmpty) return;
    if (_points.length - _deleteMarkedIndices.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Automation needs at least two points'),
          backgroundColor: AutomationEditorTheme.saveError,
        ),
      );
      return;
    }
    _pushUndo();
    setState(() {
      _points = [
        for (var i = 0; i < _points.length; i++)
          if (!_deleteMarkedIndices.contains(i)) _points[i],
      ];
      _deleteMarkedIndices.clear();
    });
    _persistPoints();
  }

  Future<void> _persistPoints() async {
    try {
      final sorted = List<AutomationPointSnapshot>.of(_points)
        ..sort((a, b) => a.beat.compareTo(b.beat));
      final snapshot = await widget.bridge.setAutomationPoints(
        clipId: widget.clip.id,
        points: sorted,
      );
      widget.onSaved(snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save automation — try again'),
            backgroundColor: AutomationEditorTheme.saveError,
          ),
        );
      }
    }
  }

  Future<void> _persistClipLength() async {
    try {
      final snapshot = await widget.bridge.setClipLength(
        clipId: widget.clip.id,
        lengthBeats: _clipLengthBeats,
      );
      widget.onSaved(snapshot);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update clip length — try again'),
            backgroundColor: AutomationEditorTheme.saveError,
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
    );
  }

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
              child: AutomationEditorViewport(
                points: _points,
                clipLengthBeats: _clipLengthBeats,
                virtualLengthBeats: _virtualLengthBeats,
                gridSettings: _grid,
                tool: _tool,
                selectedIndices: _selectedIndices,
                deleteMarkedIndices: _deleteMarkedIndices,
                insertHighlightStartBeat:
                    _insertPanelOpen ? _insertStartBeat : null,
                insertHighlightEndBeat: _insertPanelOpen ? _insertEndBeat : null,
                onPointsChanged: _onPointsChanged,
                onToggleSelect: _toggleSelect,
                onToggleDeleteMark: _toggleDeleteMark,
                onClearSelection: () => setState(_selectedIndices.clear),
                onEditStarted: _onEditStarted,
                onEditFinished: _persistPoints,
                onClipLengthChanged: (length) => setState(() => _clipLengthBeats = length),
                onClipLengthCommit: _persistClipLength,
                viewRangeBars: _viewRangeBars,
              ),
            ),
            AutomationEditorToolDock(
              tool: _tool,
              gridLabel: _gridDockLabel,
              canUndo: _undoStack.isNotEmpty,
              canRedo: _redoStack.isNotEmpty,
              canInsert: _selectedIndices.length == 2 && !_insertPanelOpen,
              canDeleteMarked: _deleteMarkedIndices.isNotEmpty,
              onToolChanged: _onToolChanged,
              onGridTap: _openGridSheet,
              onInsertTap: _openInsertPanel,
              onDeleteMarkedTap: _deleteMarkedNodes,
              onUndo: _undo,
              onRedo: _redo,
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
