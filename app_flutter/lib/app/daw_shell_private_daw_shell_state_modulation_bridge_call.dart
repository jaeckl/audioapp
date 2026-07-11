part of 'daw_shell.dart';

extension DawShellStateModulationbridgecallOperation on _DawShellState {
Future<ProjectSnapshot> _modulationBridgeCall(
    String method,
    Map<String, dynamic> args,
  ) async {
    try {
      switch (method) {
        case 'updateLfoParam':
        case 'batchUpdateLfoParams':
          await _store.invokeRaw(method, args);
          return _snapshot!;
        default:
          await _store.invokeRaw(method, args);
          return _snapshot!;
      }
    } catch (e) {
      if (!mounted) {
        return _snapshot ??
            const ProjectSnapshot(
              bpm: 120,
              selectedTrackId: '',
              playheadBeats: 0,
              playing: false,
              loopEnabled: true,
              recordArmed: false,
              master:
                  MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1.0),
              samples: [],
              tracks: [],
              lfos: [],
              modEdges: [],
            );
      }
      rethrow;
    }
  }
}
