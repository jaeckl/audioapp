part of 'daw_shell.dart';

extension DawShellStateModulationbridgecallOperation on _DawShellState {
  static const _emptyBridgeSnapshot = ProjectSnapshot(
    bpm: 120,
    selectedTrackId: '',
    playheadBeats: 0,
    playing: false,
    loopEnabled: true,
    recordArmed: false,
    master: MasterTrackSnapshot(id: 'master', name: 'Master', gain: 1.0),
    samples: [],
    tracks: [],
    lfos: [],
    modEdges: [],
  );

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
    } on PlatformException catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nestingErrorSnackMessage(e)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return _snapshot ?? _emptyBridgeSnapshot;
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nestingErrorSnackMessage(e)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return _snapshot ?? _emptyBridgeSnapshot;
    }
  }
}
