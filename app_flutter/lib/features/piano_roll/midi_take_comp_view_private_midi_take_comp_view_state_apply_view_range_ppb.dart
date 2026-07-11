part of 'midi_take_comp_view.dart';

extension _MidiTakeCompViewStateApplyviewrangeppb on _MidiTakeCompViewState {
  void _applyViewRangePpb(double viewportWidth, int bars) {
    final ppb = EditorViewRange.pixelsPerBeatForWidth(viewportWidth, bars);
    _setPixelsPerBeat(ppb);
  }
}
