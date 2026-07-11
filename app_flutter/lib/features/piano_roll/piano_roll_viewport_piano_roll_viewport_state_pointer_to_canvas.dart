part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStatePointertocanvas on PianoRollViewportState {
  Offset _pointerToCanvas(PointerEvent event) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.globalToLocal(event.position);
    }
    final sx = _horizontal.hasClients ? _horizontal.offset : 0.0;
    final sy = _vertical.hasClients ? _vertical.offset : 0.0;
    return event.localPosition + Offset(sx, sy);
  }
}
