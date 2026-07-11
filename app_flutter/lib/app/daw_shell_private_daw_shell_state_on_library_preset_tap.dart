part of 'daw_shell.dart';

extension DawShellStateOnlibrarypresettapOperation on _DawShellState {
Future<void> _onLibraryPresetTap(LibraryPresetItem item) async {
    final presetTarget = _libraryPresetDeviceId;
    if (item.isUser && item.presetJson != null && presetTarget != null) {
      try {
        final updated = await widget.bridge.applyDevicePreset(
          deviceId: presetTarget,
          presetJson: item.presetJson!,
        );
        await _refreshSnapshot(updated);
        await _libraryPanelKey.currentState?.close();
      } catch (e) {
        if (mounted) setState(() => _projectError = e.toString());
      }
      return;
    }
    if (presetTarget != null && item.deviceType != 'subtractive_synth') {
      final preset = DevicePresetStore.find(item.deviceType, item.id);
      if (preset == null) return;
      for (final entry in preset.params.entries) {
        await widget.bridge.setDeviceParameter(
          deviceId: presetTarget,
          parameterId: entry.key,
          value: entry.value,
        );
      }
      for (final entry in preset.stringParams.entries) {
        await widget.bridge.setDeviceStringParameter(
          deviceId: presetTarget,
          parameterId: entry.key,
          value: entry.value,
        );
      }
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
      await _libraryPanelKey.currentState?.close();
      return;
    }
    final drumMachineId = _libraryDrumMachineId;
    final drumNote = _libraryDrumNote;
    if (drumMachineId != null && drumNote != null) {
      const allowed = {
        'simple_sampler',
        'kick_generator',
        'snare_generator',
        'clap_generator',
        'cymbal_generator',
        'crash_generator',
      };
      if (!allowed.contains(item.deviceType)) return;
      final updated = await widget.bridge.addDeviceToDrumPad(
        drumMachineId: drumMachineId,
        note: drumNote,
        deviceType: item.deviceType,
        padName: item.title,
      );
      final machine = updated.deviceById(drumMachineId);
      final children = machine is DrumMachineDeviceSnapshot
          ? machine.padForNote(drumNote).devices
          : const <DeviceSnapshot>[];
      if (children.isNotEmpty) {
        final child = children.last;
        final preset = DevicePresetStore.find(item.deviceType, item.id);
        if (preset != null) {
          for (final entry in preset.params.entries) {
            await widget.bridge.setDeviceParameter(
              deviceId: child.id,
              parameterId: entry.key,
              value: entry.value,
            );
          }
          for (final entry in preset.stringParams.entries) {
            await widget.bridge.setDeviceStringParameter(
              deviceId: child.id,
              parameterId: entry.key,
              value: entry.value,
            );
          }
        }
      }
      await _refreshSnapshot(await widget.bridge.getProjectSnapshot());
      await _libraryPanelKey.currentState?.close();
      return;
    }
    final track = _snapshot?.selectedTrack;
    if (track == null) return;

    var synth = track.subtractiveSynthDevice;
    if (item.deviceType == 'subtractive_synth') {
      if (synth == null) {
        // Automatically add a Subtractive Synth device to the track on insert
        try {
          final snapshot = await widget.bridge.addDeviceToTrack(
            trackId: track.id,
            deviceType: 'subtractive_synth',
          );
          // Find the newly added subtractive synth device
          final updatedTrack =
              snapshot.tracks.firstWhere((t) => t.id == track.id);
          synth = updatedTrack.subtractiveSynthDevice;
          await _refreshSnapshot(snapshot);
        } catch (e) {
          if (!mounted) return;
          setState(() => _projectError = e.toString());
          return;
        }
      }

      if (synth == null) return;

      final preset = SubtractiveSynthPresets.presets[item.id];
      if (preset == null) return;

      try {
        final snapshot = await widget.bridge.applySubtractiveSynthPreset(
          deviceId: synth.id,
          params: preset.params,
          lfos: preset.lfos.map((l) => l.toJson()).toList(),
          mods: preset.mods.map((m) => m.toJson()).toList(),
        );
        await _refreshSnapshot(snapshot);
      } catch (e) {
        if (!mounted) return;
        setState(() => _projectError = e.toString());
        return;
      }

      if (!mounted) return;
      await _libraryPanelKey.currentState?.close();
      return;
    }
  }
}
