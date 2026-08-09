part of 'device_chain_row.dart';

/// Continuous edge auto-scroll while a device is dragged.
///
/// Pointer-move-only scrolling stalls when the finger holds still in the edge
/// zone and jumps too hard when events burst. A periodic ticker keeps motion
/// smooth; speed scales with how deep the finger is in the edge band.
extension _DeviceChainRowDragAutoScroll on _DeviceChainRowState {
  static const _edgePx = 96.0;
  static const _tick = Duration(milliseconds: 16);
  static const _minPxPerSec = 70.0;
  static const _maxPxPerSec = 480.0;

  void _onReorderDragPointer(Offset globalPosition) {
    _dragAutoScrollPos = globalPosition;
    _dragAutoScrollTimer ??= Timer.periodic(_tick, (_) => _tickDragAutoScroll());
  }

  void _stopDragAutoScroll() {
    _dragAutoScrollTimer?.cancel();
    _dragAutoScrollTimer = null;
    _dragAutoScrollPos = null;
  }

  void _tickDragAutoScroll() {
    final global = _dragAutoScrollPos;
    if (global == null || !_scrollController.hasClients) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final local = box.globalToLocal(global);
    final width = box.size.width;
    final x = local.dx;

    double direction = 0;
    double depth = 0;
    if (x < _edgePx) {
      direction = -1;
      depth = ((_edgePx - x) / _edgePx).clamp(0.0, 1.0);
    } else if (x > width - _edgePx) {
      direction = 1;
      depth = ((x - (width - _edgePx)) / _edgePx).clamp(0.0, 1.0);
    }
    if (direction == 0) return;

    // Quadratic ease-in: shallow edge = slow crawl, deep = faster.
    final t = depth * depth;
    final speed = _minPxPerSec + (_maxPxPerSec - _minPxPerSec) * t;
    final delta = direction * speed * (_tick.inMilliseconds / 1000.0);
    final pos = _scrollController.position;
    final next = (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
    if (next != pos.pixels) {
      _scrollController.jumpTo(next);
    }
  }
}
