part of 'midi_take_comp_view.dart';

extension _MidiTakeCompViewStateOverlay on _MidiTakeCompViewState {
  Widget _overlay(double beat) {
    final scroll = _horizontal.hasClients ? _horizontal.offset : 0.0;
    return Stack(
      children: [
        for (final marker in widget.regions.skip(1).indexed)
          _markerHandle(index: marker.$1, region: marker.$2, scroll: scroll),
        ..._playheadWidgets(beat, scroll),
      ],
    );
  }
}
