part of 'daw_shell.dart';

extension DawShellStateApplyfactorypresetjsonOperation on _DawShellState {
  Future<bool> _applyFactoryPresetJson(LibraryPresetItem item) async {
    final presetJson = FactoryPresetJson.resolveApplyJson(item.id);
    if (presetJson == null) return false;

    try {
      // Virtual substrip / strip `+` pick: let the closed-over nest host add
      // the device, then apply the preset onto the new child.
      if (await _completeDevicePickWithPreset(item)) {
        return true;
      }

      final presetTarget = _libraryPresetDeviceId;
      if (presetTarget != null) {
        final target = _snapshot?.deviceById(presetTarget);
        if (target != null && target.type == item.deviceType) {
          final updated = await widget.bridge.applyDevicePreset(
            deviceId: presetTarget,
            presetJson: presetJson,
          );
          await _refreshSnapshot(updated);
          await _libraryPanelKey.currentState?.close();
          return true;
        }
      }

      final drumMachineId = _libraryDrumMachineId;
      final drumNote = _libraryDrumNote;
      if (drumMachineId != null &&
          drumNote != null &&
          item.deviceType != 'drum_machine') {
        const allowed = {
          'simple_sampler',
          'kick_generator',
          'snare_generator',
          'clap_generator',
          'hihat_generator',
          'ride_generator',
          'tom_generator',
          'rimshot_generator',
          'crash_generator',
        };
        if (!allowed.contains(item.deviceType)) return false;

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
          final applied = await widget.bridge.applyDevicePreset(
            deviceId: children.last.id,
            presetJson: presetJson,
          );
          await _refreshSnapshot(applied);
        } else {
          await _refreshSnapshot(updated);
        }
        await _libraryPanelKey.currentState?.close();
        return true;
      }

      final track = _snapshot?.selectedTrack;
      if (track == null) return false;

      final beforeIds = track.devices.map((d) => d.id).toSet();
      final added = await widget.bridge.addDeviceToTrack(
        trackId: track.id,
        deviceType: item.deviceType,
      );
      final updatedTrack = added.tracks.firstWhere((t) => t.id == track.id);
      DeviceSnapshot? created;
      for (final device in updatedTrack.devices) {
        if (device.type == item.deviceType && !beforeIds.contains(device.id)) {
          created = device;
        }
      }
      if (created == null) {
        await _refreshSnapshot(added);
        await _libraryPanelKey.currentState?.close();
        return true;
      }

      final applied = await widget.bridge.applyDevicePreset(
        deviceId: created.id,
        presetJson: presetJson,
      );
      await _refreshSnapshot(applied);
      await _libraryPanelKey.currentState?.close();
      return true;
    } catch (e) {
      if (mounted) setState(() => _projectError = e.toString());
      return true; // handled; don't fall through to legacy path
    }
  }
}
