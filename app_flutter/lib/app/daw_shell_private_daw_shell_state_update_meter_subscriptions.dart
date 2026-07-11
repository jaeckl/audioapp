part of 'daw_shell.dart';

extension DawShellStateUpdatemetersubscriptionsOperation on _DawShellState {
Future<void> _updateMeterSubscriptions(List<String> deviceIds) async {
    if (_tab == _ShellTab.mixer) {
      deviceIds = [
        for (final track in _snapshot?.tracks ?? const <TrackSnapshot>[])
          if (track.trackGainDevice != null) track.trackGainDevice!.id,
      ];
    } else if (_tab != _ShellTab.devices) {
      deviceIds = const [];
    }
    if (listEquals(deviceIds, _meterSubscriptionIds)) return;
    _meterSubscriptionIds = deviceIds;
    try {
      await widget.bridge.setMeterSubscriptions(deviceIds);
    } catch (_) {}
  }
}
