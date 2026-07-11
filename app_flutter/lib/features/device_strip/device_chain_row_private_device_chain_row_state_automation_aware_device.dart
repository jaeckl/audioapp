part of 'device_chain_row.dart';

extension _DeviceChainRowStateAutomationawaredevice on _DeviceChainRowState {
  Widget _automationAwareDevice(
    DeviceSnapshot device,
    Widget Function(DeviceSnapshot displayDevice) builder,
  ) {
    DeviceSnapshot at(double beat) => applyLiveAutomation(
          device,
          widget.projectAutomationClips,
          beat,
        );
    final playhead = widget.playheadBeatListenable;
    if (playhead == null) return builder(at(widget.playheadBeat));
    return ValueListenableBuilder<double>(
      valueListenable: playhead,
      builder: (_, beat, __) => builder(at(beat)),
    );
  }
}
