part of 'daw_shell.dart';

extension DawShellStateFlushqueuedwtpositionparameterOperation on _DawShellState {
Future<void> _flushQueuedWtPositionParameter() async {
    _pendingWtPositionTimer = null;
    if (_wtPositionSendInFlight) {
      _pendingWtPositionTimer = Timer(
        const Duration(milliseconds: 16),
        _flushQueuedWtPositionParameter,
      );
      return;
    }

    final deviceId = _pendingWtPositionDeviceId;
    final value = _pendingWtPositionValue;
    _pendingWtPositionDeviceId = null;
    _pendingWtPositionValue = null;
    if (deviceId == null || value == null) return;

    _wtPositionSendInFlight = true;
    try {
      await widget.bridge.setDeviceParameter(
        deviceId: deviceId,
        parameterId: 'wtPosition',
        value: value,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _projectError = e.toString());
      }
    } finally {
      _wtPositionSendInFlight = false;
      if (mounted &&
          _pendingWtPositionDeviceId != null &&
          _pendingWtPositionTimer == null) {
        _pendingWtPositionTimer = Timer(
          const Duration(milliseconds: 16),
          _flushQueuedWtPositionParameter,
        );
      }
    }
  }
}
