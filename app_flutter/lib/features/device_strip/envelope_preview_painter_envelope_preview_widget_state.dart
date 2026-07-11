part of 'envelope_preview_painter.dart';

class _EnvelopePreviewWidgetState extends State<EnvelopePreviewWidget> {
  int? _draggingNode;
  bool _draggingCurvature = false;

  static const _padding = EdgeInsets.fromLTRB(10, 8, 10, 20);

  Size _effectiveSize(Size total) => Size(
        total.width - _padding.left - _padding.right,
        total.height - _padding.top - _padding.bottom,
      );

  Offset _toEffective(Offset pos) => Offset(
        pos.dx - _padding.left,
        pos.dy - _padding.top,
      );

  EnvelopePreviewPainter _painter() => EnvelopePreviewPainter(
        attack: widget.attack,
        hold: widget.hold,
        decay: widget.decay,
        sustain: widget.sustain,
        release: widget.release,
        curveType: widget.curveType,
        delay: widget.delay,
        attackCurve: widget.attackCurve,
        decayCurve: widget.decayCurve,
        releaseCurve: widget.releaseCurve,
        analogMode: widget.analogMode,
      );

  double _paramValue(String param) {
    switch (param) {
      case 'delay':
        return widget.delay;
      case 'attack':
        return widget.attack;
      case 'hold':
        return widget.hold;
      case 'decay':
        return widget.decay;
      case 'sustain':
        return widget.sustain;
      case 'release':
        return widget.release;
      case 'attackCurve':
        return widget.attackCurve;
      case 'decayCurve':
        return widget.decayCurve;
      case 'releaseCurve':
        return widget.releaseCurve;
      default:
        return 0.0;
    }
  }

  void _onPanStart(DragStartDetails details) {
    final size = context.size;
    if (size == null) return;
    final painter = _painter();
    final hit = painter.nearestInteractive(
      _toEffective(details.localPosition),
      _effectiveSize(size),
    );
    setState(() {
      _draggingNode = hit.index;
      _draggingCurvature = hit.isCurvature;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final node = _draggingNode;
    if (node == null || node < 0) return;
    final size = context.size;
    if (size == null) return;
    final effectiveSize = _effectiveSize(size);

    final painter = _painter();
    final pts = painter.computeBreakpoints(effectiveSize);

    if (_draggingCurvature) {
      // Dragging a curvature handle — vertical motion adjusts curvature
      final curves = painter.curvedSegments(effectiveSize);
      if (node < curves.length) {
        final seg = curves[node];
        final delta = -details.delta.dy / effectiveSize.height * 2.0;
        final current = _paramValue(seg.param);
        widget.onChanged(seg.param, (current + delta).clamp(0.0, 1.0));
      }
      return;
    }

    if (node >= pts.length) return;

    final param =
        EnvelopePreviewPainter.paramForNodeIndex(node, widget.curveType);
    if (param == null) return;

    final isSustainNode = painter._isSustainNode(node, pts);

    if (param != 'sustain') {
      final delta = details.delta.dx / effectiveSize.width;
      final current = _paramValue(param);
      widget.onChanged(param, (current + delta).clamp(0.0, 1.0));
    }

    if (isSustainNode) {
      final delta = details.delta.dy / effectiveSize.height;
      widget.onChanged('sustain', (widget.sustain - delta).clamp(0.0, 1.0));
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _draggingNode = null;
      _draggingCurvature = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAnalog = widget.analogMode != 0;
    const accent = Color(0xFFE8A54B);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: _painter(),
              size: Size.infinite,
            ),
          ),
        ),
        // Analog/Digital toggle top-right
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => widget.onChanged('analogMode', isAnalog ? 0.0 : 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isAnalog
                    ? accent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isAnalog ? accent : Colors.white24,
                  width: 1,
                ),
              ),
              child: Text(
                isAnalog ? 'AN' : 'DG',
                style: TextStyle(
                  color: isAnalog ? accent : Colors.white54,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
