part of 'curve_editor_screen.dart';

class _CurveEditorScreenState extends State<CurveEditorScreen> {
  static const Color _bgDark = Color(0xFF14141E);

  late List<double> _positions;
  late List<double> _values;
  late List<int> _shapes;
  int _bpCount = 0;
  int? _draggingIndex;
  CurveEditorTool _tool = CurveEditorTool.select;
  AutomationCurveShape? _paintShape;
  late int _polarity;
  List<double>? _shapeSourcePositions;
  List<double>? _shapeSourceValues;
  List<int>? _shapeSourceKinds;
  double? _shapeStart;
  double? _shapeEnd;
  double? _shapeBaseline;

  /// Selected point indices (max 2) for shape insertion.
  final Set<int> _selectedIndices = {};

  int get _lastIdx => _bpCount - 1;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Tracks the pending save future so PopScope can await it before popping.
  Future<void>? _pendingSave;

  @override
  void initState() {
    super.initState();
    _importMod();
  }

  @override
  void didUpdateWidget(CurveEditorScreen old) {
    super.didUpdateWidget(old);
    if (old.mod.id != widget.mod.id) _importMod();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double _valueClamp(double v) =>
      _polarity == 0 ? v.clamp(-1.0, 1.0) : v.clamp(0.0, 1.0);

  double _nx(Offset localPos, Size s) =>
      (localPos.dx / s.width).clamp(0.0, 1.0);
  double _ny(Offset localPos, Size s) =>
      _valueClamp(1.0 - 2.0 * localPos.dy / s.height);

  double _snapPhase(double value) =>
      (value * _gridDivisions).round() / _gridDivisions;

  // ---------------------------------------------------------------------------
  // Point selection
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Shape generation between two anchor points
  // ---------------------------------------------------------------------------

  /// Generate breakpoints for [shapeName] between [posStart]..[posEnd],
  /// producing linear breakpoints that approximate the waveform with
  /// [cycles] repetitions. Anchor positions/values are preserved exactly.
  /// Replace all breakpoints strictly between two anchor points with a
  /// shaped curve, then sync to bridge.
  /// Open bottom sheet to pick shape type and parameters, then insert.
  // ---------------------------------------------------------------------------
  // Gesture handlers
  // ---------------------------------------------------------------------------

  // --- Select ---

  // --- Draw ---

  /// Points accumulated during the current draw gesture.
  final List<double> _drawAccPos = [];
  final List<double> _drawAccVal = [];

  /// Rebuild breakpoints keeping everything outside the draw X range and
  /// replacing everything inside with the accumulated draw points.
  // --- Tap dispatch ---

  // --- Erase ---

  // ---------------------------------------------------------------------------
  // Toolbar
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await widget.onBatchUpdate(_collectUpdates());
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: _bgDark,
        appBar: AppBar(
          backgroundColor: _bgDark,
          foregroundColor: Colors.white,
          title: Text('CURVE ${widget.mod.id}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          centerTitle: true,
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
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text('CURVE ${widget.mod.id}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('$_bpCount pts',
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            _buildToolbar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cs =
                          Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTapUp: (d) => _onTapUp(d, cs),
                        onPanStart: (d) => _onPanStart(d, cs),
                        onPanUpdate: (d) => _onPanUpdate(d, cs),
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: _CurveEditorPainter(
                            positions: _positions,
                            values: _values,
                            shapes: _shapes,
                            polarity: _polarity,
                            highlightedIndex: _draggingIndex,
                            selectedIndices: _selectedIndices,
                            shapeHighlightStart: _shapeStart,
                            shapeHighlightEnd: _shapeEnd,
                            accent: _accent,
                          ),
                          size: cs,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
