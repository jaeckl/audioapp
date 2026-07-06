import 'package:flutter/material.dart';

/// Tap a timeline beat without firing on scroll drags or during pinch.
class EditorBeatTapSurface extends StatefulWidget {
  const EditorBeatTapSurface({
    super.key,
    required this.pixelsPerBeat,
    required this.maxBeat,
    required this.enabled,
    required this.onBeat,
    required this.child,
  });

  final double pixelsPerBeat;
  final double maxBeat;
  final bool enabled;
  final ValueChanged<double> onBeat;
  final Widget child;

  static const double tapSlop = 10;

  @override
  State<EditorBeatTapSurface> createState() => _EditorBeatTapSurfaceState();
}

class _EditorBeatTapSurfaceState extends State<EditorBeatTapSurface> {
  int? _pointer;
  Offset? _last;
  double _travel = 0;

  void _onDown(PointerDownEvent event) {
    if (!widget.enabled || _pointer != null) return;
    _pointer = event.pointer;
    _last = event.localPosition;
    _travel = 0;
  }

  void _onMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _last == null) return;
    _travel += (event.localPosition - _last!).distance;
    _last = event.localPosition;
  }

  void _onEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (widget.enabled &&
        _travel < EditorBeatTapSurface.tapSlop &&
        widget.pixelsPerBeat > 0) {
      final beat = (event.localPosition.dx / widget.pixelsPerBeat)
          .clamp(0.0, widget.maxBeat);
      widget.onBeat(beat);
    }
    _pointer = null;
    _last = null;
    _travel = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onEnd,
      onPointerCancel: _onEnd,
      child: widget.child,
    );
  }
}
