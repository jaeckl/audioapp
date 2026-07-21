part of 'midi_take_comp_view.dart';

extension _MidiTakeCompViewStateSetpixelsperbeat on _MidiTakeCompViewState {
  void _setPixelsPerBeat(double next, {Offset? focal}) {
    final clamped = next.clamp(
      PianoRollMetrics.minPixelsPerBeat,
      PianoRollMetrics.maxPixelsPerBeat,
    );
    if ((clamped - _pixelsPerBeat).abs() < 0.05) return;

    final oldPpb = _pixelsPerBeat;
    final scrollX = _horizontal.hasClients ? _horizontal.offset : 0.0;
    final focalDx = focal?.dx ??
        (_horizontal.hasClients
            ? _horizontal.position.viewportDimension / 2
            : 0);
    final beatAtFocal = (scrollX + focalDx) / oldPpb;

    setState(() => _pixelsPerBeat = clamped);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_horizontal.hasClients) return;
      final maxX = _horizontal.position.maxScrollExtent;
      final newScrollX = (beatAtFocal * clamped - focalDx).clamp(0.0, maxX);
      _horizontal.jumpTo(newScrollX);
      if (_ruler.hasClients) _ruler.jumpTo(newScrollX);
    });
  }
}
