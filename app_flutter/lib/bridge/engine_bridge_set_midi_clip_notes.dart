part of 'engine_bridge.dart';

extension EngineBridgeSetmidiclipnotesOperation on EngineBridge {
Future<ProjectSnapshot> setMidiClipNotes({
    required String clipId,
    required List<MidiNoteSnapshot> notes,
  }) async {
    return _invokeForSnapshot('setMidiClipNotes', {
      'clipId': clipId,
      'notes': notes
          .map((n) => {
                'pitch': n.pitch,
                'startBeat': n.startBeat,
                'durationBeats': n.durationBeats,
                'velocity': n.velocity,
              })
          .toList(),
    });
  }
}
