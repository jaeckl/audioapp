part of 'daw_shell.dart';

extension DawShellStateQueuewtpositionparameterOperation on _DawShellState {
void _queueWtPositionParameter(String deviceId, double value) {
    _pendingWtPositionDeviceId = deviceId;
    _pendingWtPositionValue = value.clamp(0.0, 1.0).toDouble();
    _pendingWtPositionTimer ??= Timer(
      const Duration(milliseconds: 16),
      _flushQueuedWtPositionParameter,
    );
  }
}
