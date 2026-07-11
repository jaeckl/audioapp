part of 'engine_bridge.dart';

class LiveMidiNoteEvent {
  const LiveMidiNoteEvent.noteOn({
    required this.pitch,
    required this.velocity,
  }) : allOff = false;

  const LiveMidiNoteEvent.noteOff({required this.pitch})
      : velocity = 0,
        allOff = false;

  const LiveMidiNoteEvent.allOff()
      : pitch = -1,
        velocity = 0,
        allOff = true;

  final int pitch;
  final double velocity;
  final bool allOff;
  bool get isNoteOn => !allOff && velocity > 0;
}
