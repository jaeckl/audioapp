part of 'multiband_split_panel.dart';

/// Log-Hz crossover editor styled after the reverb response panel:
/// dark fill, soft grid, labeled log ticks, circular drag handles.
class MultibandCrossoverEditor extends StatefulWidget {
  const MultibandCrossoverEditor({
    super.key,
    required this.bandCount,
    required this.crossoverHz,
    required this.accent,
    required this.onCrossoverChanged,
  });

  final int bandCount;
  final List<double> crossoverHz;
  final Color accent;
  final void Function(int index, double hz) onCrossoverChanged;

  static const double minHz = 20;
  static const double maxHz = 20000;
  static const double gapRatio = 1.25;
  /// Half-width of grab zone (~100px total) around each crossover line.
  static const double handleHitRadius = 50;
  static const double labelBand = 16;

  @override
  State<MultibandCrossoverEditor> createState() =>
      _MultibandCrossoverEditorState();
}

class _MultibandCrossoverEditorState extends State<MultibandCrossoverEditor> {
  int? _dragIndex;

  static double hzToX(double hz, double width) {
    final clamped = hz.clamp(
        MultibandCrossoverEditor.minHz, MultibandCrossoverEditor.maxHz);
    final norm = math.log(clamped / MultibandCrossoverEditor.minHz) /
        math.log(MultibandCrossoverEditor.maxHz /
            MultibandCrossoverEditor.minHz);
    return norm * width;
  }

  static double xToHz(double x, double width) {
    if (width <= 0) return MultibandCrossoverEditor.minHz;
    final norm = (x / width).clamp(0.0, 1.0);
    return MultibandCrossoverEditor.minHz *
        math.pow(
            MultibandCrossoverEditor.maxHz / MultibandCrossoverEditor.minHz,
            norm);
  }

  double _clampAt(int index, double hz) {
    var lo = MultibandCrossoverEditor.minHz;
    var hi = MultibandCrossoverEditor.maxHz;
    final gap = MultibandCrossoverEditor.gapRatio;
    if (index > 0 && index - 1 < widget.crossoverHz.length) {
      lo = math.max(lo, widget.crossoverHz[index - 1] * gap);
    }
    if (index + 1 < widget.crossoverHz.length) {
      hi = math.min(hi, widget.crossoverHz[index + 1] / gap);
    }
    if (lo > hi) return widget.crossoverHz[index];
    return hz.clamp(lo, hi);
  }

  int? _nearestHandle(double x, double width, List<double> xo) {
    final radius = MultibandCrossoverEditor.handleHitRadius;
    int? best;
    var bestDist = radius;
    for (var i = 0; i < xo.length; i++) {
      final dist = (hzToX(xo[i], width) - x).abs();
      if (dist <= bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  void _setHz(int index, double x, double width) {
    widget.onCrossoverChanged(index, _clampAt(index, xToHz(x, width)));
  }

  @override
  Widget build(BuildContext context) {
    final xoCount = widget.bandCount - 1;
    final xo = widget.crossoverHz.take(xoCount).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final plotH = math.max(0.0, h - MultibandCrossoverEditor.labelBand);

        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _CrossoverPainter(
                  crossoverHz: xo,
                  accent: widget.accent,
                  dragIndex: _dragIndex,
                  plotHeight: plotH,
                ),
              ),
              // Full-height grab; eager horizontal drag wins vs strip scroll.
              Positioned.fill(
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: <Type, GestureRecognizerFactory>{
                    _EagerHandleDragRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            _EagerHandleDragRecognizer>(
                      () => _EagerHandleDragRecognizer(
                        shouldClaim: (local) =>
                            _nearestHandle(local.dx, w, xo) != null,
                      ),
                      (instance) {
                        instance.onStart = (details) {
                          final i =
                              _nearestHandle(details.localPosition.dx, w, xo);
                          if (i == null) return;
                          setState(() => _dragIndex = i);
                          _setHz(i, details.localPosition.dx, w);
                        };
                        instance.onUpdate = (details) {
                          final i = _dragIndex;
                          if (i == null) return;
                          _setHz(i, details.localPosition.dx, w);
                        };
                        instance.onEnd = (_) {
                          setState(() => _dragIndex = null);
                        };
                        instance.onCancel = () {
                          setState(() => _dragIndex = null);
                        };
                      },
                    ),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CrossoverPainter extends CustomPainter {
  const _CrossoverPainter({
    required this.crossoverHz,
    required this.accent,
    required this.dragIndex,
    required this.plotHeight,
  });

  final List<double> crossoverHz;
  final Color accent;
  final int? dragIndex;
  final double plotHeight;

  static String _fmt(double hz) {
    if (hz >= 1000) {
      final k = hz / 1000;
      return k >= 10 ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
    }
    return '${hz.round()}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(0, 0, size.width, plotHeight);
    canvas.drawRect(plot, Paint()..color = const Color(0xFF0E0E14));

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = plotHeight * i / 4;
      canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), grid);
    }

    // Major log-Hz ticks + labels (EQ-style mapping 20 Hz … 20 kHz).
    const labeled = [20.0, 100.0, 1000.0, 10000.0, 20000.0];
    const minors = [50.0, 200.0, 500.0, 2000.0, 5000.0];
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    for (final hz in minors) {
      final x = _MultibandCrossoverEditorState.hzToX(hz, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, plotHeight), tickPaint);
    }
    for (final hz in labeled) {
      final x = _MultibandCrossoverEditorState.hzToX(hz, size.width);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, plotHeight),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: _fmt(hz),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelX = (x - tp.width / 2).clamp(2.0, size.width - tp.width - 2);
      tp.paint(canvas, Offset(labelX, plotHeight + 2));
    }

    // Soft band fills between crossovers.
    final edges = <double>[
      0,
      for (final hz in crossoverHz)
        _MultibandCrossoverEditorState.hzToX(hz, size.width),
      size.width,
    ];
    for (var b = 0; b < edges.length - 1; b++) {
      final left = edges[b];
      final right = edges[b + 1];
      if (right <= left) continue;
      canvas.drawRect(
        Rect.fromLTRB(left, 0, right, plotHeight),
        Paint()..color = accent.withValues(alpha: b.isEven ? 0.06 : 0.03),
      );
    }

    for (var i = 0; i < crossoverHz.length; i++) {
      final x = _MultibandCrossoverEditorState.hzToX(crossoverHz[i], size.width);
      final active = dragIndex == i;
      canvas.drawLine(
        Offset(x, 4),
        Offset(x, plotHeight - 4),
        Paint()
          ..color = active ? accent : accent.withValues(alpha: 0.75)
          ..strokeWidth = active ? 2 : 1.5,
      );

      final center = Offset(x, plotHeight * 0.5);
      // Reverb-style handle: soft halo + solid disc + white rim.
      canvas.drawCircle(
        center,
        14,
        Paint()..color = accent.withValues(alpha: active ? 0.22 : 0.12),
      );
      canvas.drawCircle(center, 6, Paint()..color = accent);
      canvas.drawCircle(
        center,
        6,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: _fmt(crossoverHz[i]),
          style: TextStyle(
            color: accent,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, 6));
    }
  }

  @override
  bool shouldRepaint(covariant _CrossoverPainter old) =>
      old.accent != accent ||
      old.dragIndex != dragIndex ||
      old.plotHeight != plotHeight ||
      !_listEq(old.crossoverHz, crossoverHz);

  static bool _listEq(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Wins the gesture arena against the parent horizontal strip scroll when the
/// pointer is near a crossover handle.
class _EagerHandleDragRecognizer extends HorizontalDragGestureRecognizer {
  _EagerHandleDragRecognizer({
    required this.shouldClaim,
  });

  final bool Function(Offset localPosition) shouldClaim;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (!shouldClaim(event.localPosition)) return;
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void rejectGesture(int pointer) {
    // If scrollable tries to beat us after the fact, keep the handle drag.
    acceptGesture(pointer);
  }
}
