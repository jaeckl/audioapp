part of 'engine_bridge.dart';

extension EngineBridgeNoteonOperation on EngineBridge {
  Future<void> noteOn({required int pitch, required double velocity}) async {
    _noteEvents.add(LiveMidiNoteEvent.noteOn(
      pitch: pitch,
      velocity: velocity,
    ));
    await _invokeOk('noteOn', {'pitch': pitch, 'velocity': velocity});
  }
}
