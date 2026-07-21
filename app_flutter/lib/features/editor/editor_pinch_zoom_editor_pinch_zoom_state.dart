part of 'editor_pinch_zoom.dart';

class _EditorPinchZoomState extends State<EditorPinchZoom> {
  final _positions = <int, Offset>{};
  double _initialDistance = 1;

  double get _distance {
    if (_positions.length < 2) return 1;
    final points = _positions.values.take(2).toList();
    return math.max(12, (points[0] - points[1]).distance);
  }

  Offset get _focal {
    if (_positions.length < 2) return Offset.zero;
    final points = _positions.values.take(2).toList();
    return (points[0] + points[1]) / 2;
  }

  void _down(PointerDownEvent event) {
    _positions[event.pointer] = event.localPosition;
    if (_positions.length == 2) {
      _initialDistance = _distance;
      widget.onStart(_focal);
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
