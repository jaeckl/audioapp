part of 'daw_shell.dart';

extension DawShellStateCreatesamplerfromdroppedsampleOperation on _DawShellState {
Future<void> _createSamplerFromDroppedSample(
    TrackSnapshot track,
    SampleClipDragData sample,
    int insertIndex,
  ) async {
    try {
      final beforeIds = track.devices.map((device) => device.id).toSet();
      final snapshot = await widget.bridge.addDeviceToTrack(
        trackId: track.id,
        deviceType: 'simple_sampler',
        insertIndex: insertIndex,
      );
      final updatedTrack = snapshot.tracks.firstWhere((t) => t.id == track.id);
      SamplerDeviceSnapshot? sampler;
      for (final device in updatedTrack.devices) {
        if (device is SamplerDeviceSnapshot && !beforeIds.contains(device.id)) {
          sampler = device;
          break;
        }
      }
      await _refreshSnapshot(snapshot);
      if (sampler == null) return;
      await _setDeviceStringParameter(sampler.id, 'sampleId', sample.sampleId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _projectError = e.toString());
    }
  }
}
