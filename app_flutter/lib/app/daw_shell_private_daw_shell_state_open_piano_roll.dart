part of 'daw_shell.dart';

extension DawShellStateOpenpianorollOperation on _DawShellState {
Future<void> _openPianoRoll(String trackId, MidiClipSnapshot clip) async {
    TrackSnapshot? track;
    for (final t in _snapshot?.tracks ?? const <TrackSnapshot>[]) {
      if (t.id == trackId) {
        track = t;
        break;
      }
    }
    if (track == null) return;

    DrumMachineDeviceSnapshot? drumMachine;
    for (final device in track.visibleDevices) {
      if (device is DrumMachineDeviceSnapshot) {
        drumMachine = device;
        break;
      }
    }
    final drumLaneLayout = drumMachine == null
        ? null
        : MidiLaneLayout(
            drumMachine.pads
                .where((pad) => pad.devices.isNotEmpty)
                .map((pad) => MidiLaneDefinition(
                      pitch: pad.note,
                      name: pad.name.isNotEmpty
                          ? pad.name
                          : MidiLaneLayout.defaultName(pad.note),
                    )),
          );

    final savedPlayhead = await _beginClipEditorSession();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => PianoRollScreen(
          bridge: widget.bridge,
          clip: clip,
          trackName: track!.name,
          bpm: _snapshot?.bpm ?? 120,
          drumAnchorPitch: track.drumAnchorPitch,
          drumLaneLayout:
              drumLaneLayout?.isNotEmpty == true ? drumLaneLayout : null,
          onSnapshot: _refreshSnapshot,
          savedArrangementPlayhead: savedPlayhead,
        ),
      ),
    );
    await _endClipEditorSession();

    try {
      final snapshot = await widget.bridge.getProjectSnapshot();
      await _refreshSnapshot(snapshot);
    } catch (_) {}
  }
}
