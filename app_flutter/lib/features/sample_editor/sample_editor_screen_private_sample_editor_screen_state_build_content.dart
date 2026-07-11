part of 'sample_editor_screen.dart';

extension SampleEditorScreenStateBuildcontentOperation on _SampleEditorScreenState {
Widget _buildContent(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AutomationEditorTheme.background,
        appBar: AppBar(
          backgroundColor: AutomationEditorTheme.background,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
              '${widget.trackName} · ${widget.clip.sampleName.isEmpty ? 'Sample' : widget.clip.sampleName}',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          actions: [
            TextButton.icon(
              onPressed: _openSnapSettings,
              icon: const Icon(Icons.crop_free, size: 17),
              label: Text('Snap $_snapLabel'),
            ),
            if (saving)
              const Padding(
                  padding: EdgeInsets.all(18),
                  child: SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))),
          ],
        ),
        body: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: Column(children: [
            Container(
              height: 46,
              color: AutomationEditorTheme.dockBackground,
              child: Row(children: [
                _ToolButton(
                    icon: Icons.pan_tool_alt_outlined,
                    label: 'MOVE',
                    tooltip: 'Move and zoom timeline',
                    active: tool == _SampleTool.navigate,
                    onTap: () => setState(() => tool = _SampleTool.navigate)),
                _ToolButton(
                    icon: Icons.content_cut,
                    label: 'TRIM',
                    tooltip: 'Trim',
                    active: tool == _SampleTool.trim,
                    onTap: () => setState(() => tool = _SampleTool.trim)),
                _ToolButton(
                    icon: Icons.show_chart,
                    label: 'FADE',
                    tooltip: 'Fade',
                    active: tool == _SampleTool.fade,
                    onTap: () => setState(() => tool = _SampleTool.fade)),
                _ToolButton(
                    icon: Icons.vertical_split,
                    label: 'SLICE',
                    tooltip: 'Slice',
                    active: tool == _SampleTool.slice,
                    onTap: () => setState(() => tool = _SampleTool.slice)),
                _ToolButton(
                    icon: Icons.layers_outlined,
                    label: 'TAKES',
                    tooltip: 'Take comping',
                    active: tool == _SampleTool.take,
                    onTap: () => setState(() => tool = _SampleTool.take)),
                _ToolButton(
                    icon: Icons.tune,
                    label: 'PROCESS',
                    tooltip: 'Clip processing',
                    active: tool == _SampleTool.process,
                    onTap: () => setState(() => tool = _SampleTool.process)),
                const Spacer(),
                _ToolButton(
                    icon: transport.isPlaying ? Icons.stop : Icons.play_arrow,
                    compact: true,
                    tooltip: transport.isPlaying ? 'Stop' : 'Preview',
                    active: transport.isPlaying,
                    onTap: _audition),
                const SizedBox(width: 4),
              ]),
            ),
            Expanded(
                child: _SampleTimeline(
              clipName: widget.clip.sampleName,
              peaks: _displayWaveformPeaks,
              clipLengthBeats: widget.clip.lengthBeats,
              naturalLengthBeats: widget.clip.effectiveNaturalLengthBeats,
              playbackContentLengthBeats: _playbackContentLengthBeats,
              start: start,
              end: end,
              fadeIn: fadeIn,
              fadeOut: fadeOut,
              fadeInCurve: fadeInCurve,
              fadeOutCurve: fadeOutCurve,
              gain: gain,
              reversed: reversed,
              pixelsPerBeat: pixelsPerBeat,
              gridStepBeats:
                  SnapGridResolution.adaptive.beatsForZoom(pixelsPerBeat),
              onZoomStart: () => zoomStart = pixelsPerBeat,
              onZoomScale: (scale) => setState(
                  () => pixelsPerBeat = (zoomStart * scale).clamp(24.0, 640.0)),
              clipInteracting: clipInteracting,
              pinchInteracting: pinchInteracting,
              onPinchInteractionChanged: (active) {
                if (pinchInteracting != active) {
                  setState(() => pinchInteracting = active);
                }
              },
              trimToolActive: tool == _SampleTool.trim,
              fadeToolActive: tool == _SampleTool.fade,
              takeToolActive: tool == _SampleTool.take,
              takes: widget.clip.takes,
              takeRegions: takeRegions,
              selectedTakeMarker: selectedTakeMarker,
              samples: widget.samples,
              onTakeAtBeat: _setTakeAtBeat,
              onTakeMarkerSelect: _selectTakeMarker,
              onTakeMarkerMove: _moveTakeMarker,
              onTakeMarkerMoveEnd: _saveTakeMarkerMove,
              sliceToolActive: tool == _SampleTool.slice,
              sliceMarkers: List.of(sliceMarkers),
              onSliceToggle: _toggleSlice,
              onSliceSelect: _selectSliceMarker,
              selectedSlice: selectedSlice,
              selectedMarker: selectedMarker,
              onSliceMove: _moveSlice,
              onSliceMoveEnd: _saveSlices,
              onSliceAudition: _auditionSlice,
              onPlayheadSeek: transport.seekClipLocal,
              onPlayheadActivate: _audition,
              onClipInteractionChanged: (active) {
                if (clipInteracting != active)
                  setState(() => clipInteracting = active);
              },
              playhead: transport.clipLocalBeat,
              onTrimChanged: (nextStart, nextEnd) {
                setState(() {
                  start = _snapSource(nextStart).clamp(0.0, end - .001);
                  end = _snapSource(nextEnd).clamp(start + .001, 1.0);
                });
                _syncPreviewTransportSpan();
              },
              onFadesChanged: (nextIn, nextOut) => setState(() {
                fadeIn = nextIn;
                fadeOut = nextOut;
              }),
              onCurvesChanged: (nextIn, nextOut) => setState(() {
                fadeInCurve = nextIn;
                fadeOutCurve = nextOut;
              }),
              onEditEnd: _save,
            )),
            _SampleToolCard(
              child: switch (tool) {
                _SampleTool.take => SampleEditorTakeToolsPanel(
                    playheadBeat: transport.clipLocalBeat,
                    selectedMarkerBeat: selectedTakeMarker == null ||
                            selectedTakeMarker! < 0 ||
                            selectedTakeMarker! >= _takeMarkerBeats.length
                        ? null
                        : _takeMarkerBeats[selectedTakeMarker!],
                    onSplitAtPlayhead: _splitTakeAtPlayhead,
                    onDeleteSelected: _deleteSelectedTakeMarker,
                    onNudgeSelected: _nudgeSelectedTakeMarker,
                  ),
                _SampleTool.process => _ProcessPanel(
                    gain: gain,
                    loop: loopContent,
                    repitch: warpRepitch,
                    reversed: reversed,
                    onGainChanged: (value) {
                      setState(() => gain = value);
                      _scheduleSave();
                    },
                    onLoop: () => _handleMenuAction(_SampleMenuAction.loop),
                    onRepitch: () => _handleMenuAction(_SampleMenuAction.warp),
                    onReverse: () =>
                        _handleMenuAction(_SampleMenuAction.reverse),
                    onNormalize: () =>
                        _handleMenuAction(_SampleMenuAction.normalize),
                  ),
                _SampleTool.slice => _SlicePanel(
                    sensitivity: transientSensitivity,
                    autoMode: sliceAutoMode,
                    minGap: sliceMinGap,
                    replaceExisting: sliceReplaceExisting,
                    evenDivisions: sliceEvenDivisions,
                    gridDivision: sliceGridDivision,
                    firstNote: sliceFirstNote,
                    status: sliceStatus,
                    selectedMarkerPosition: selectedMarker == null ||
                            selectedMarker! < 0 ||
                            selectedMarker! >= sliceMarkers.length
                        ? null
                        : sliceMarkers[selectedMarker!],
                    onSensitivityChanged: (value) =>
                        setState(() => transientSensitivity = value),
                    onAutoModeChanged: (value) =>
                        setState(() => sliceAutoMode = value),
                    onMinGapChanged: (value) =>
                        setState(() => sliceMinGap = value),
                    onReplaceExistingChanged: (value) =>
                        setState(() => sliceReplaceExisting = value),
                    onEvenDivisionsChanged: (value) =>
                        setState(() => sliceEvenDivisions = value),
                    onGridDivisionChanged: (value) =>
                        setState(() => sliceGridDivision = value),
                    onFirstNoteChanged: (value) =>
                        setState(() => sliceFirstNote = value),
                    onAutoSlice: _autoSlice,
                    onReset: _resetSlices,
                    onDeleteSelected: _deleteSelectedSliceMarker,
                    onNudgeSelected: _nudgeSelectedSliceMarker,
                    onAuditionSelected: _auditionSelectedSliceMarker,
                    onExport: _exportSlices,
                  ),
                _ => _ClipEditPanel(
                    tool: tool,
                    gain: gain,
                    start: start,
                    end: end,
                    fadeIn: fadeIn,
                    fadeOut: fadeOut,
                    fadeInCurve: fadeInCurve,
                    fadeOutCurve: fadeOutCurve,
                    onGainChanged: (value) {
                      setState(() => gain = value);
                      _scheduleSave();
                    },
                    onCurveChanged: (nextIn, nextOut) {
                      setState(() {
                        fadeInCurve = nextIn;
                        fadeOutCurve = nextOut;
                      });
                      _scheduleSave();
                    },
                  ),
              },
            ),
          ]),
        ),
      );
}
