part of 'device_chain_row.dart';

const _slNestingRejectedTypes = {
  'device_chain',
  'lr_split',
  'ms_split',
  'mb_split_2',
  'mb_split_3',
  'mb_split_4',
  'spectral_loud_split',
};

extension _DeviceChainRowStateVirtualspectralloudband on _DeviceChainRowState {
  Widget _virtualSpectralLoudBand(
    BuildContext context,
    SpectralLoudSplitDeviceSnapshot device,
    int bandIndex,
  ) {
    final accent = DeviceStripTheme.spectralLoudBandColor(bandIndex);
    final bandDevices = device.bandDevices(bandIndex);
    final label = SpectralLoudSplitDeviceSnapshot.bandLabels[bandIndex];
    Future<void> addDevice() async {
      final type = await showDevicePickerSheet(context);
      if (type == null || _slNestingRejectedTypes.contains(type)) return;
      await widget.onModulationBridgeCall?.call('addDeviceToSpectralLoudBand', {
        'deviceId': device.id,
        'bandIndex': bandIndex,
        'deviceType': type,
      });
    }

    return _spectralVirtualStrip(
      accent: accent,
      title: label,
      devices: bandDevices,
      onAdd: addDevice,
      removeArgs: (childId) => {
        'deviceId': device.id,
        'bandIndex': bandIndex,
        'childId': childId,
      },
      removeMethod: 'removeDeviceFromSpectralLoudBand',
    );
  }

  Widget _virtualSpectralLoudPreFx(
    BuildContext context,
    SpectralLoudSplitDeviceSnapshot device,
  ) {
    final accent = DeviceStripTheme.accentForDeviceType(device.type);
    Future<void> addDevice() async {
      final type = await showDevicePickerSheet(context);
      if (type == null || _slNestingRejectedTypes.contains(type)) return;
      await widget.onModulationBridgeCall?.call('addDeviceToSpectralLoudPreFx', {
        'deviceId': device.id,
        'deviceType': type,
      });
    }

    return _spectralVirtualStrip(
      accent: accent,
      title: 'PRE',
      devices: device.preFxDevices,
      onAdd: addDevice,
      removeArgs: (childId) => {
        'deviceId': device.id,
        'childId': childId,
      },
      removeMethod: 'removeDeviceFromSpectralLoudPreFx',
    );
  }

  Widget _virtualSpectralLoudPostFx(
    BuildContext context,
    SpectralLoudSplitDeviceSnapshot device,
  ) {
    final accent = DeviceStripTheme.accentForDeviceType(device.type);
    Future<void> addDevice() async {
      final type = await showDevicePickerSheet(context);
      if (type == null || _slNestingRejectedTypes.contains(type)) return;
      await widget.onModulationBridgeCall
          ?.call('addDeviceToSpectralLoudPostFx', {
        'deviceId': device.id,
        'deviceType': type,
      });
    }

    return _spectralVirtualStrip(
      accent: accent,
      title: 'POST',
      devices: device.postFxDevices,
      onAdd: addDevice,
      removeArgs: (childId) => {
        'deviceId': device.id,
        'childId': childId,
      },
      removeMethod: 'removeDeviceFromSpectralLoudPostFx',
    );
  }

  Widget _spectralVirtualStrip({
    required Color accent,
    required String title,
    required List<DeviceSnapshot> devices,
    required Future<void> Function() onAdd,
    required Map<String, dynamic> Function(String childId) removeArgs,
    required String removeMethod,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: CustomPaint(
        painter: _VirtualChainBracketPainter(accent),
        child: ColoredBox(
          color: accent.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 4, 9, 4),
            child: Row(children: [
              RotatedBox(
                  quarterTurns: 3,
                  child: Text(title,
                      style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8))),
              const SizedBox(width: 7),
              for (final child in devices) ...[
                _automationAwareDevice(
                    child,
                    (displayChild) => _sampleDropTarget(
                        enabled: _canAcceptSampleDrop(child) &&
                            widget.onAssignDroppedSampleToDevice != null,
                        onAccept: (sample) => widget
                            .onAssignDroppedSampleToDevice!(child, sample),
                        child: DeviceStripSlot(
                          track: widget.track,
                          routingSources: const [],
                          device: displayChild,
                          sample: _sampleFor(child),
                          bpm: widget.bpm,
                          playheadBeat: widget.playheadBeat,
                          playheadBeatListenable: widget.playheadBeatListenable,
                          liveMetersListenable: widget.liveMetersListenable,
                          playing: widget.playing,
                          density: widget.density,
                          samplerTab: widget.samplerTabFor?.call(child.id) ??
                              SamplerDeviceTab.wave,
                          synthTab: widget.synthTabFor?.call(child.id) ??
                              SubtractiveDeviceTab.osc,
                          onSamplerParameterChanged: (id, value) => widget
                              .onSamplerParameterChanged(child.id, id, value),
                          onDeviceParameterChanged: (id, value) => widget
                              .onSamplerParameterChanged(child.id, id, value),
                          onDeviceStringParameterChanged: (id, value) => widget
                              .onDeviceStringParameterChanged
                              ?.call(child.id, id, value),
                          onOpenSamplerEditor: () =>
                              widget.onOpenSamplerEditor(widget.track, child),
                          onFrequencyChanged: (value) =>
                              widget.onFrequencyChanged(child.id, value),
                          onBypassToggle: widget.onBypassToggle == null
                              ? null
                              : () => widget.onBypassToggle!(
                                  child.id, !child.bypassed),
                          onDeleteRequest: () => widget.onModulationBridgeCall
                              ?.call(removeMethod, removeArgs(child.id)),
                          onOpenLibrary: widget.onOpenLibrary == null
                              ? null
                              : (filter) =>
                                  widget.onOpenLibrary!(child, filter),
                          onPreviewSample: widget.onPreviewSample,
                          onPreviewSampler: widget.onPreviewSampler,
                          lfos: widget.lfos,
                          modEdges: widget.modEdges,
                          onModulationBridgeCall: widget.onModulationBridgeCall,
                          automationLinkActive: widget.automationLinkActive,
                          automationLinkClipId: widget.automationLinkClipId,
                          projectAutomationClips: widget.projectAutomationClips,
                          onAutomationParamSelected:
                              widget.onAutomationParamSelected,
                          onAutomateParameter: widget.onAutomateParameter,
                          onGetParamDescriptors: widget.onGetParamDescriptors,
                        ))),
                const SizedBox(width: 5),
              ],
              if (devices.length < 8)
                SizedBox(
                  width: DeviceStripMetrics.separatorWidth,
                  child: Center(
                      child: DeviceInsertSlot(
                          accentColor: accent, onPressed: onAdd)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
