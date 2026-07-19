part of 'daw_shell.dart';

extension DawShellStatePendinginsertpresetOperation on _DawShellState {
  static const _nestAddMethods = {
    'addDeviceToChain',
    'addDeviceToSynthAudioFx',
    'addDeviceToSynthNoteFx',
    'addDeviceToSplitBranch',
    'addDeviceToMultibandBand',
    'addDeviceToSpectralLoudBand',
    'addDeviceToSpectralLoudPreFx',
    'addDeviceToSpectralLoudPostFx',
    'addDeviceToDrumPad',
  };

  /// Queue a preset to apply after the pending device-pick insert lands
  /// (track `+` or virtual substrip). Returns false if [presetJson] missing.
  bool _queuePresetForDevicePick({
    required String deviceType,
    required String presetJson,
  }) {
    _pendingInsertPresetJson = presetJson;
    _pendingInsertPresetDeviceType = deviceType;
    _pendingInsertPresetBeforeIds = _collectAllDeviceIds(_snapshot);
    return true;
  }

  void _clearPendingInsertPreset() {
    _pendingInsertPresetJson = null;
    _pendingInsertPresetDeviceType = null;
    _pendingInsertPresetBeforeIds = null;
  }

  /// Completes an open library device-pick with [item]'s type and queues
  /// preset apply. Returns true when the pick was consumed.
  Future<bool> _completeDevicePickWithPreset(LibraryPresetItem item) async {
    final pick = _libraryDevicePickCompleter;
    if (pick == null || pick.isCompleted) return false;

    final presetJson =
        item.presetJson ?? FactoryPresetJson.resolveApplyJson(item.id);
    if (presetJson == null) return false;

    _queuePresetForDevicePick(
      deviceType: item.deviceType,
      presetJson: presetJson,
    );
    pick.complete(item.deviceType);
    _libraryDevicePickCompleter = null;
    await _libraryPanelKey.currentState?.close();
    return true;
  }

  /// Used by [DeviceChainScreen]'s own pick completer (same queue).
  bool _onQueuePresetForDevicePick(LibraryPresetItem item) {
    final presetJson =
        item.presetJson ?? FactoryPresetJson.resolveApplyJson(item.id);
    if (presetJson == null) return false;
    return _queuePresetForDevicePick(
      deviceType: item.deviceType,
      presetJson: presetJson,
    );
  }

  Future<void> _flushPendingInsertPreset() async {
    final json = _pendingInsertPresetJson;
    final type = _pendingInsertPresetDeviceType;
    final before = _pendingInsertPresetBeforeIds;
    if (json == null || type == null || before == null) return;
    _clearPendingInsertPreset();

    final snap = _snapshot;
    if (snap == null) return;
    final created = _findNewDeviceOfType(snap, type, before);
    if (created == null) return;

    try {
      final updated = await widget.bridge.applyDevicePreset(
        deviceId: created.id,
        presetJson: json,
      );
      await _refreshSnapshot(updated);
    } catch (e) {
      if (mounted) setState(() => _projectError = e.toString());
    }
  }

  Set<String> _collectAllDeviceIds(ProjectSnapshot? snap) {
    final ids = <String>{};
    if (snap == null) return ids;
    void walk(Iterable<DeviceSnapshot> devices) {
      for (final device in devices) {
        ids.add(device.id);
        if (device is ChainDeviceSnapshot) walk(device.devices);
        if (device is SplitDeviceSnapshot) {
          walk(device.branch0);
          walk(device.branch1);
        }
        if (device is MultibandSplitDeviceSnapshot) {
          for (final band in device.bands) {
            walk(band);
          }
        }
        if (device is SpectralLoudSplitDeviceSnapshot) {
          for (final band in device.bands) {
            walk(band);
          }
          walk(device.preFxDevices);
          walk(device.postFxDevices);
        }
        if (device is DrumMachineDeviceSnapshot) {
          for (final pad in device.pads) {
            walk(pad.devices);
          }
        }
        if (device.audioFxDevices.isNotEmpty) walk(device.audioFxDevices);
        if (device.noteFxDevices.isNotEmpty) walk(device.noteFxDevices);
      }
    }

    for (final track in snap.tracks) {
      walk(track.devices);
    }
    walk(snap.master.devices);
    return ids;
  }

  DeviceSnapshot? _findNewDeviceOfType(
    ProjectSnapshot snap,
    String type,
    Set<String> beforeIds,
  ) {
    DeviceSnapshot? found;
    void walk(Iterable<DeviceSnapshot> devices) {
      for (final device in devices) {
        if (device.type == type && !beforeIds.contains(device.id)) {
          found = device;
        }
        if (device is ChainDeviceSnapshot) walk(device.devices);
        if (device is SplitDeviceSnapshot) {
          walk(device.branch0);
          walk(device.branch1);
        }
        if (device is MultibandSplitDeviceSnapshot) {
          for (final band in device.bands) {
            walk(band);
          }
        }
        if (device is SpectralLoudSplitDeviceSnapshot) {
          for (final band in device.bands) {
            walk(band);
          }
          walk(device.preFxDevices);
          walk(device.postFxDevices);
        }
        if (device is DrumMachineDeviceSnapshot) {
          for (final pad in device.pads) {
            walk(pad.devices);
          }
        }
        if (device.audioFxDevices.isNotEmpty) walk(device.audioFxDevices);
        if (device.noteFxDevices.isNotEmpty) walk(device.noteFxDevices);
      }
    }

    for (final track in snap.tracks) {
      walk(track.devices);
    }
    walk(snap.master.devices);
    return found;
  }

  bool _isNestAddMethod(String method) => _nestAddMethods.contains(method);
}
