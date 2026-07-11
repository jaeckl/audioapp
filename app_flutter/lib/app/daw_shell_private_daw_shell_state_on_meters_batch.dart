part of 'daw_shell.dart';

extension DawShellStateOnmetersbatchOperation on _DawShellState {
void _onMetersBatch(LiveMetersBatch batch) {
    if (!mounted) return;
    _liveMeters.applyBatch(batch);
  }
}
