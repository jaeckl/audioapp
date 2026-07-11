part of 'arrangement_view.dart';

extension ArrangementViewStateOnscaleupdateOperation on ArrangementViewState {
void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) {
      return;
    }

    final next = (_scaleStartPixelsPerBeat * details.scale).clamp(
      _minimumPixelsPerBeat,
      ArrangementTimelineMetrics.maxPixelsPerBeat,
    );
    if ((next - _pixelsPerBeat).abs() < 0.25) {
      return;
    }

    final scrollX =
        _horizontalScroll.hasClients ? _horizontalScroll.offset : 0.0;
    final focalX = details.focalPoint.dx;
    final beatAtFocal = (scrollX + focalX) / _pixelsPerBeat;

    setState(() => _pixelsPerBeat = next);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_horizontalScroll.hasClients) {
        return;
      }
      final targetOffset = beatAtFocal * next - focalX;
      final maxExtent = _horizontalScroll.position.maxScrollExtent;
      _horizontalScroll.jumpTo(targetOffset.clamp(0.0, maxExtent));
    });
  }
}
