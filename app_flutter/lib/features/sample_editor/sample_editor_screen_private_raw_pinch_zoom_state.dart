part of 'sample_editor_screen.dart';

class _RawPinchZoomState extends State<_RawPinchZoom> {
  final positions = <int, Offset>{};
  double initialDistance = 1;

  double get distance {
    if (positions.length < 2) return 1;
    final points = positions.values.take(2).toList();
    return math.max(12, (points[0] - points[1]).distance);
  }

  void down(PointerDownEvent event) {
    positions[event.pointer] = event.localPosition;
    if (positions.length == 2) {
      initialDistance = distance;
      widget.onStart();
      widget.onPinchChanged(true);
    }
  }

  void move(PointerMoveEvent event) {
    if (!positions.containsKey(event.pointer)) return;
    positions[event.pointer] = event.localPosition;
    if (positions.length >= 2) widget.onScale(distance / initialDistance);
  }

  void remove(PointerEvent event) {
    positions.remove(event.pointer);
    if (positions.length < 2) widget.onPinchChanged(false);
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: down,
        onPointerMove: move,
        onPointerUp: remove,
        onPointerCancel: remove,
        child: widget.child,
      );
}
