part of 'midi_take_comp_view.dart';

extension _MidiTakeCompViewStateSyncruler on _MidiTakeCompViewState {
  void _syncRuler() {
    if (_syncingRuler || !_ruler.hasClients) return;
    _syncingRuler = true;
    _ruler
        .jumpTo(_horizontal.offset.clamp(0.0, _ruler.position.maxScrollExtent));
    _syncingRuler = false;
  }
}
