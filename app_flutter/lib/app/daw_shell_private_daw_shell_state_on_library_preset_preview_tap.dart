part of 'daw_shell.dart';

extension DawShellStateOnlibrarypresetpreviewtapOperation on _DawShellState {
  Future<void> _onLibraryPresetPreviewTap(LibraryPresetItem item,
      {double startBeat = 0.0, bool loop = true}) async {
    final previewType =
        FactoryPresetJson.previewDeviceType(item.id) ?? item.deviceType;
    if (!FactoryPresetJson.supportsAudioPreview(previewType)) {
      debugPrint(
          '[library preset] skip audio preview for $previewType (${item.id})');
      return;
    }

    final params = FactoryPresetJson.flatParamsForPreview(item.id) ??
        DevicePresetStore.find(item.deviceType, item.id)?.params;
    debugPrint(
        '[library preset] item.id=${item.id} deviceType=${item.deviceType} '
        'previewType=$previewType startBeat=$startBeat loop=$loop '
        'presetFound=${params != null}');
    if (params == null) {
      return;
    }

    final loopEnd = _snapshot?.loopRegionEndBeat ?? 16.0;
    // Preset preview always uses the short factory demo phrase — never arrangement clips.
    final previewNotes = libraryPresetDemoArpeggio;
    final lengthBeats = math.max(loopEnd, 4.0);

    final bpm = _snapshot?.bpm ?? 120;
    try {
      await widget.bridge.previewPreset(
        deviceType: previewType,
        params: params,
        notes: previewNotes,
        lengthBeats: lengthBeats,
        bpm: bpm,
        startBeat: startBeat,
        loop: loop,
      );
    } catch (e) {
      debugPrint('[library preset] previewPreset FAILED for ${item.id}: $e');
    }
  }
}
