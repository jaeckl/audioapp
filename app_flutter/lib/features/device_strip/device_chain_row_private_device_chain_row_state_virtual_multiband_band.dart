part of 'device_chain_row.dart';

const _mbNestingRejectedTypes = {
  'device_chain',
  'lr_split',
  'ms_split',
  'mb_split_2',
  'mb_split_3',
  'mb_split_4',
  'spectral_loud_split',
};

extension _DeviceChainRowStateVirtualmultibandband on _DeviceChainRowState {
  String _mbBandLabel(MultibandSplitDeviceSnapshot mb, int bandIndex) {
    final labels = MultibandSplitDeviceSnapshot.bandLabels(mb.bandCount);
    if (bandIndex >= 0 && bandIndex < labels.length) return labels[bandIndex];
    return 'B${bandIndex + 1}';
  }

  Widget _virtualMultibandBand(
    BuildContext context,
    MultibandSplitDeviceSnapshot mb,
    int bandIndex,
  ) {
    final accent = DeviceStripTheme.accentForDeviceType(mb.type);
    final bandDevices = mb.bandDevices(bandIndex);
    Future<void> addDevice() async {
      final type = widget.onPickDeviceType != null
          ? await widget.onPickDeviceType!()
          : await showDevicePickerSheet(context);
      if (type == null || _mbNestingRejectedTypes.contains(type)) return;
      await widget.onModulationBridgeCall?.call('addDeviceToMultibandBand', {
        'mbId': mb.id,
        'bandIndex': bandIndex,
        'deviceType': type,
      });
    }

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
                  child: Text(_mbBandLabel(mb, bandIndex),
                      style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8))),
              const SizedBox(width: 7),
              for (final child in bandDevices) ...[
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
                              ?.call('removeDeviceFromMultibandBand', {
                            'mbId': mb.id,
                            'bandIndex': bandIndex,
                            'deviceId': child.id,
                          }),
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
              if (bandDevices.length < 8)
                SizedBox(
                  width: DeviceStripMetrics.separatorWidth,
                  child: Center(
                      child: DeviceInsertSlot(
                          accentColor: accent, onPressed: addDevice)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
