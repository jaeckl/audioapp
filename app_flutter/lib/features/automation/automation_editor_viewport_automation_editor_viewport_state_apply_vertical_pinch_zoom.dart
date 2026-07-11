part of 'automation_editor_viewport.dart';

extension _AutomationEditorViewportStateApplyverticalpinchzoom
    on AutomationEditorViewportState {
  void _applyVerticalPinchZoom(double scale, Offset focal) {
    final newValueH = AutomationEditorMetrics.clampValueAxisHeight(
      _pinchStartValueH * scale,
      _canvasViewportHeight,
    );

    if ((newValueH - _valueAxisHeight).abs() < 0.15) {
      return;
    }

    final scrollY = _vertical.hasClients ? _vertical.offset : 0.0;
    final valueAtFocal =
        AutomationEditorMetrics.valueFromDy(focal.dy, _valueAxisHeight);

    setState(() {
      _valueAxisHeight = newValueH;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_vertical.hasClients) return;
      final maxY = _vertical.position.maxScrollExtent;
      final valueY =
          AutomationEditorMetrics.dyFromValue(valueAtFocal, newValueH);
      final newScrollY = (valueY - focal.dy + scrollY).clamp(0.0, maxY);
      _vertical.jumpTo(newScrollY);
      if (_verticalLabels.hasClients) _verticalLabels.jumpTo(newScrollY);
    });
  }
}
