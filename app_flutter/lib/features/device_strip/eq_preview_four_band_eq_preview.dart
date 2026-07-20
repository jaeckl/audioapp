part of 'eq_preview.dart';

class FourBandEqPreview extends StatefulWidget {
  const FourBandEqPreview({
    super.key,
    required this.bands,
    required this.accent,
    this.selectedBandIndex = 0,
    this.bandColors = const [],
    this.onBandSelected,
    this.onBandEdited,
  });

  /// Exactly 4 entries: [lowShelf, lowMidPeak, highMidPeak, highShelf].
  final List<EqBand> bands;
  final Color accent;
  final int selectedBandIndex;
  final List<Color> bandColors;

  /// Tap / drag start selects a band (0..3).
  final ValueChanged<int>? onBandSelected;

  /// Drag reports normalized freq + gain for band [index].
  final void Function(int index, double freqNorm, double gainNorm)? onBandEdited;

  @override
  State<FourBandEqPreview> createState() => _FourBandEqPreviewState();
}

class _FourBandEqPreviewState extends State<FourBandEqPreview> {
  int? _dragIndex;
  Size _size = Size.zero;

  int? _nearest(Offset local) {
    if (_size == Size.zero || widget.bands.isEmpty) return null;
    var best = -1;
    var bestDist = EqPreviewGeometry.hitRadius;
    for (var i = 0; i < widget.bands.length; i++) {
      final p = EqPreviewGeometry.handleOffset(widget.bands[i], _size);
      final d = (p - local).distance;
      if (d <= bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best < 0 ? null : best;
  }

  void _applyDrag(int index, Offset local) {
    final edit = widget.onBandEdited;
    if (edit == null || _size == Size.zero) return;

    var hz = EqPreviewGeometry.localToFreq(local.dx, _size);
    // Soft order: keep shelves / peaks from crossing neighbors.
    if (index > 0) {
      hz = math.max(hz, widget.bands[index - 1].cutoffHz * 1.02);
    }
    if (index < widget.bands.length - 1) {
      hz = math.min(hz, widget.bands[index + 1].cutoffHz / 1.02);
    }
    hz = hz.clamp(EqPreviewGeometry.minFreq, EqPreviewGeometry.maxFreq);

    final db = EqPreviewGeometry.localToDb(local.dy, _size)
        .clamp(EqPreviewGeometry.minDb, EqPreviewGeometry.maxDb);

    edit(
      index,
      EqPreviewGeometry.hzToNorm(hz),
      EqPreviewGeometry.dbToNorm(db),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _EqPreviewPainter(
                bands: widget.bands,
                accent: widget.accent,
                selectedBandIndex: widget.selectedBandIndex,
                bandColors: widget.bandColors,
                dragIndex: _dragIndex,
              ),
            ),
            Positioned.fill(
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: <Type, GestureRecognizerFactory>{
                  _EagerPanRecognizer:
                      GestureRecognizerFactoryWithHandlers<_EagerPanRecognizer>(
                    () => _EagerPanRecognizer(
                      shouldClaim: (local) => _nearest(local) != null,
                    ),
                    (instance) {
                      instance.onStart = (details) {
                        final i = _nearest(details.localPosition);
                        if (i == null) return;
                        setState(() => _dragIndex = i);
                        widget.onBandSelected?.call(i);
                        _applyDrag(i, details.localPosition);
                      };
                      instance.onUpdate = (details) {
                        final i = _dragIndex;
                        if (i == null) return;
                        _applyDrag(i, details.localPosition);
                      };
                      instance.onEnd = (_) => setState(() => _dragIndex = null);
                      instance.onCancel =
                          () => setState(() => _dragIndex = null);
                    },
                  ),
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
