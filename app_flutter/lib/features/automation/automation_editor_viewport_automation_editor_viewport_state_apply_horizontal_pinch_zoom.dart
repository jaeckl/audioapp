part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateApplyhorizontalpinchzoom
    on AutomationEditorViewportState {
  void _applyHorizontalPinchZoom(double scale, Offset focal) {
    final newPpb = (_pinchStartPpb * scale).clamp(
      _minimumPixelsPerBeat,
      AutomationEditorMetrics.maxPixelsPerBeat,
    );

    if ((newPpb - _pixelsPerBeat).abs() < 0.05) {
      return;
    }

    final scrollX = _horizontal.hasClients ? _horizontal.offset : 0.0;
    final beatAtFocal = focal.dx / _pixelsPerBeat;

    setState(() {
      _pixelsPerBeat = newPpb;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_horizontal.hasClients) return;
      final maxX = _horizontal.position.maxScrollExtent;
      final newScrollX =
          (beatAtFocal * newPpb - focal.dx + scrollX).clamp(0.0, maxX);
      _horizontal.jumpTo(newScrollX);
      if (_ruler.hasClients) _ruler.jumpTo(newScrollX);
    });
  }
}
