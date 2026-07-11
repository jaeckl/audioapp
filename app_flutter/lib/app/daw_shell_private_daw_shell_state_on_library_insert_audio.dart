part of 'daw_shell.dart';

extension DawShellStateOnlibraryinsertaudioOperation on _DawShellState {
Future<void> _onLibraryInsertAudio(SampleLibraryEntrySnapshot sample) async {
    final drumMachineId = _libraryDrumMachineId;
    final drumNote = _libraryDrumNote;
    if (drumMachineId != null && drumNote != null) {
      final updated = await widget.bridge.addDeviceToDrumPad(
        drumMachineId: drumMachineId,
        note: drumNote,
        deviceType: 'simple_sampler',
        padName: sample.name,
      );
      final machine = updated.deviceById(drumMachineId);
      if (machine is DrumMachineDeviceSnapshot) {
        final samplers = machine
            .padForNote(drumNote)
            .devices
            .whereType<SamplerDeviceSnapshot>()
            .toList();
        if (samplers.isNotEmpty) {
          await _refreshSnapshot(updated);
          await _assignSamplerSample(samplers.last.id, sample.id);
        }
      }
      await _libraryPanelKey.currentState?.close();
      return;
    }
    final deviceId = _librarySamplerDeviceId;
    if (deviceId != null) {
      await _assignSamplerSample(deviceId, sample.id);
      await _libraryPanelKey.currentState?.close();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${sample.name}')),
        );
      }
      return;
    }
    await _insertSample(sample);
  }
}
