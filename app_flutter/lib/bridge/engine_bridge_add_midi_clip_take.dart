part of 'engine_bridge.dart';

extension EngineBridgeAddmidicliptakeOperation on EngineBridge {
  Future<ProjectSnapshot> addMidiClipTake({
    required String clipId,
    required String name,
    required double startBeatOffset,
    required double lengthBeats,
    required List<MidiNoteSnapshot> notes,
  }) async {
    return _invokeForSnapshot('addMidiClipTake', {
      'clipId': clipId,
      'name': name,
      'startBeatOffset': startBeatOffset,
      'lengthBeats': lengthBeats,
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
