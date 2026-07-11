part of 'engine_bridge.dart';

extension EngineBridgeAllnotesoffOperation on EngineBridge {
  Future<void> allNotesOff() async {
    _noteEvents.add(const LiveMidiNoteEvent.allOff());
    await _invokeOk('allNotesOff');
  }
}
