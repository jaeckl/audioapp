part of 'daw_shell.dart';

extension DawShellStateOptimisticparamupdateOperation on _DawShellState {
void _optimisticParamUpdate(
      String deviceId, String parameterId, double value) {
    _store.replaceSnapshot(
        _snapshot!.withDeviceParam(deviceId, parameterId, value));
  }
}
