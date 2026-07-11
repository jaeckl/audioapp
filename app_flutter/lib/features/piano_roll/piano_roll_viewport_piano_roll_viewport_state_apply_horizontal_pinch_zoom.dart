part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateApplyhorizontalpinchzoom
    on PianoRollViewportState {
  void _applyHorizontalPinchZoom(double scale, Offset focal) {
    final newPpb = (_pinchStartPpb * scale).clamp(
      _minimumPixelsPerBeat,
      PianoRollMetrics.maxPixelsPerBeat,
    );

    if ((newPpb - _pixelsPerBeat).abs() < 0.15) {
      return;
    }

    final scrollX = _horizontal.hasClients ? _horizontal.offset : 0.0;
    final beatAtFocal = focal.dx / _pixelsPerBeat;

    setState(() {
      _pixelsPerBeat = newPpb;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_horizontal.hasClients) return;
      final maxX = _horizontal.position.maxScrollExtent;
      final newScrollX =
          (beatAtFocal * newPpb - focal.dx + scrollX).clamp(0.0, maxX);
      _horizontal.jumpTo(newScrollX);
      if (_ruler.hasClients) _ruler.jumpTo(newScrollX);
    });
  }
}
