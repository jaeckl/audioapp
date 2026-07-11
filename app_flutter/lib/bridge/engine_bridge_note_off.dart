part of 'engine_bridge.dart';

extension EngineBridgeNoteoffOperation on EngineBridge {
  Future<void> noteOff({required int pitch}) async {
    _noteEvents.add(LiveMidiNoteEvent.noteOff(pitch: pitch));
    await _invokeOk('noteOff', {'pitch': pitch});
  }
}
