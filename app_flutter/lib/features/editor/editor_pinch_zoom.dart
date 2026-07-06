import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Raw two-finger pinch scale for timeline editors (horizontal zoom).
class EditorPinchZoom extends StatefulWidget {
  const EditorPinchZoom({
    super.key,
    required this.child,
    required this.onStart,
    required this.onScale,
    required this.onPinchChanged,
  });

  final Widget child;
  final VoidCallback onStart;
  final ValueChanged<double> onScale;
  final ValueChanged<bool> onPinchChanged;

  @override
  State<EditorPinchZoom> createState() => _EditorPinchZoomState();
}

class _EditorPinchZoomState extends State<EditorPinchZoom> {
  final _positions = <int, Offset>{};
  double _initialDistance = 1;

  double get _distance {
    if (_positions.length < 2) return 1;
    final points = _positions.values.take(2).toList();
    return math.max(12, (points[0] - points[1]).distance);
  }

  void _down(PointerDownEvent event) {
    _positions[event.pointer] = event.localPosition;
    if (_positions.length == 2) {
      _initialDistance = _distance;
      widget.onStart();
      widget.onPinchChanged(true);
    }
  }

  void _move(PointerMoveEvent event) {
    if (!_positions.containsKey(event.pointer)) return;
    _positions[event.pointer] = event.localPosition;
    if (_positions.length >= 2) {
      widget.onScale(_distance / _initialDistance);
    }
  }

  void _remove(PointerEvent event) {
    _positions.remove(event.pointer);
    if (_positions.length < 2) widget.onPinchChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _remove,
      onPointerCancel: _remove,
      child: widget.child,
    );
  }
}
