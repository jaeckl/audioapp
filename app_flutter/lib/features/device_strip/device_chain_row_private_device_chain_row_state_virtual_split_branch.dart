part of 'device_chain_row.dart';

const _splitNestingRejectedTypes = {
  'device_chain',
  'lr_split',
  'ms_split',
  'mb_split_2',
  'mb_split_3',
  'mb_split_4',
  'spectral_loud_split',
};

extension _DeviceChainRowStateVirtualsplitbranch on _DeviceChainRowState {
  String _splitBranchLabel(SplitDeviceSnapshot split, int branchIndex) {
    if (split.isMidSide) return branchIndex == 0 ? 'MID' : 'SIDE';
    return branchIndex == 0 ? 'L' : 'R';
  }

  Widget _virtualSplitBranch(
    BuildContext context,
    SplitDeviceSnapshot split,
    int branchIndex,
  ) {
    final accent = DeviceStripTheme.accentForDeviceType(split.type);
    final branchDevices = split.branchDevices(branchIndex);
    Future<void> addDevice() async {
      final type = await showDevicePickerSheet(context);
      if (type == null || _splitNestingRejectedTypes.contains(type)) return;
      await widget.onModulationBridgeCall?.call('addDeviceToSplitBranch', {
        'splitId': split.id,
        'branchIndex': branchIndex,
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
                  child: Text(_splitBranchLabel(split, branchIndex),
                      style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8))),
              const SizedBox(width: 7),
              for (final child in branchDevices) ...[
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
                              ?.call('removeDeviceFromSplitBranch', {
                            'splitId': split.id,
                            'branchIndex': branchIndex,
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
              if (branchDevices.length < 8)
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
