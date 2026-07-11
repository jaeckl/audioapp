part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateApplyverticalpinchzoom
    on PianoRollViewportState {
  void _applyVerticalPinchZoom(double scale, Offset focal) {
    final newRowH = (_pinchStartRowH * scale)
        .clamp(PianoRollMetrics.minRowHeight, PianoRollMetrics.maxRowHeight);

    if ((newRowH - _rowHeight).abs() < 0.15) {
      return;
    }

    final scrollY = _vertical.hasClients ? _vertical.offset : 0.0;
    final rowAtFocal = focal.dy / _rowHeight;

    setState(() {
      _rowHeight = newRowH;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_vertical.hasClients) return;
      final maxY = _vertical.position.maxScrollExtent;
      final newScrollY =
          (rowAtFocal * newRowH - focal.dy + scrollY).clamp(0.0, maxY);
      _vertical.jumpTo(newScrollY);
      if (_verticalKeys.hasClients) _verticalKeys.jumpTo(newScrollY);
    });
  }
}
