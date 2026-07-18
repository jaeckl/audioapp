part of 'piano_roll_screen.dart';

extension PianoRollScreenStateBuildcontentOperation on _PianoRollScreenState {
  Widget _buildContent(BuildContext context) {
    final barCount = (_clipLengthBeats / PianoRollMetrics.beatsPerBar).ceil();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _closeEditor();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: PianoRollTheme.background,
        appBar: AppBar(
          backgroundColor: PianoRollTheme.background,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeEditor,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.trackName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _appBarSubtitle(barCount),
                style: const TextStyle(
                  color: PianoRollTheme.labelMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'View',
              icon: const Icon(Icons.grid_view_rounded, size: 22),
              color: Colors.white70,
              onPressed: _openViewSheet,
            ),
            if (_takes.length > 1)
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                color: const Color(0xFF1A1A22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF343442)),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'flatten':
                      unawaited(_flattenMidiComp());
                    case 'reopen':
                      unawaited(_reopenMidiComp());
                  }
                },
                itemBuilder: (context) => [
                  if (_takes.length > 1 && !_compFlattened)
                    const PopupMenuItem(
                      value: 'flatten',
                      child: Text('Flatten comp'),
                    ),
                  if (_compFlattened)
                    const PopupMenuItem(
                      value: 'reopen',
                      child: Text('Re-open comp'),
                    ),
                ],
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: Column(
            children: [
              PianoRollContextStrip(
                centerMode: _centerMode,
                onCenterModeChanged: _onCenterModeChanged,
                showCompTab: _takes.length > 1,
                showHarmonicTab: _editorMode == MidiEditorMode.piano,
                snapLabel: _snapChipLabel,
                scaleLabel: _scaleChipLabel,
                onViewTap: _openViewSheet,
                modeChip: _modeChip,
              ),
              if (_toolMode == PianoRollCenterMode.harmonic && !_showTakes)
                HarmonicToolPanel(
                  scale: _scale.scale,
                  rootPitchClass: _scale.rootPitchClass,
                  armedDegree: _armedDegree,
                  params: _harmonicParams,
                  onDegreeTap: _onHarmonicDegreeTap,
                  onParamsChanged: (p) => setState(() => _harmonicParams = p),
                ),
              if (_toolMode == PianoRollCenterMode.progression && !_showTakes)
                ProgressionToolPanel(
                  genre: _progressionGenre,
                  subgenreId: _progressionSubgenreId,
                  templateId: _progressionTemplateId,
                  onGenreChanged: (g) => setState(() {
                    _progressionGenre = g;
                    _ensureProgressionSelection();
                  }),
                  onSubgenreChanged: (id) => setState(() {
                    _progressionSubgenreId = id;
                    _ensureProgressionSelection();
                  }),
                  onTemplateChanged: (id) =>
                      setState(() => _progressionTemplateId = id),
                ),
              if (_toolMode == PianoRollCenterMode.rhythm && !_showTakes)
                RhythmToolPanel(
                  genre: _rhythmGenre,
                  subgenreId: _rhythmSubgenreId,
                  rhythmId: _rhythmPresetId,
                  onGenreChanged: (g) {
                    setState(() {
                      _rhythmGenre = g;
                      _ensureRhythmSelection();
                    });
                  },
                  onSubgenreChanged: (id) {
                    setState(() {
                      _rhythmSubgenreId = id;
                      _ensureRhythmSelection();
                    });
                  },
                  onRhythmChanged: _onRhythmChanged,
                ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _previewTransport,
                  builder: (context, _) {
                    if (_showTakes && _takes.isNotEmpty) {
                      return MidiTakeCompView(
                        compNotes: _notes,
                        takes: _takes,
                        regions: _takeRegions,
                        clipLengthBeats: _clipLengthBeats,
                        virtualLengthBeats: _virtualLengthBeats,
                        viewRangeBars: _viewRangeBars,
                        compTool: _compTool,
                        playheadBeat: _previewTransport.clipLocalBeat,
                        readOnly: _compFlattened,
                        selectedMarker: _selectedTakeMarker,
                        onPlayheadSeek: _previewTransport.seekClipLocal,
                        onMarkerSelected: (index) =>
                            setState(() => _selectedTakeMarker = index),
                        onMarkerMove: _moveMidiTakeMarker,
                        onMarkerMoveEnd: (index, beat) =>
                            _saveMidiTakeMarkerMove(index, beat),
                        onTakeAtBeat: _setMidiTakeAtBeat,
                      );
                    }
                    return PianoRollViewport(
                      timelineScrollController: _timelineScrollController,
                      notes: _notes,
                      clipLengthBeats: _clipLengthBeats,
                      virtualLengthBeats: _virtualLengthBeats,
                      minPitch: PianoRollMetrics.gridMinPitch,
                      maxPitch: PianoRollMetrics.gridMaxPitch,
                      drumAnchorPitch: widget.drumAnchorPitch,
                      laneLayout: _editorMode == MidiEditorMode.drums
                          ? widget.drumLaneLayout
                          : null,
                      gridSettings: _grid,
                      scaleSettings: _scale,
                      tool: _isHarmonyTool
                          ? PianoRollTool.select
                          : _tool,
                      drawPattern: _drawPattern,
                      selectedIndex: _selectedIndex,
                      chordGroupEdit: _isHarmonyTool,
                      chordGroupSelected: _harmonyChordSelected,
                      chordSlots: _chordSlots,
                      onChordSlotsChanged: (slots) =>
                          setState(() => _chordSlots = slots),
                      onChordGroupSelectedChanged: (chord) =>
                          setState(() => _harmonyChordSelected = chord),
                      onHarmonyInsertTap:
                          _showHarmonyInsert ? _onRollPlusTap : null,
                      harmonyInsertTooltip:
                          _toolMode == PianoRollCenterMode.harmonic
                              ? 'Insert chord after last chord'
                              : 'Insert progression after last chord',
                      onNotesChanged: _onNotesChanged,
                      onSelectionChanged: (index) => setState(() {
                        _selectedIndex = index;
                        if (index == null) _harmonyChordSelected = true;
                      }),
                      onEditStarted: _onEditStarted,
                      onEditFinished: _onEditFinished,
                      onClipLengthChanged: (length) {
                        setState(() => _clipLengthBeats = length);
                        _previewTransport.maxClipBeat = length;
                      },
                      onClipLengthCommit: _persistClipLength,
                      viewRangeBars: _viewRangeBars,
                      virtualPlayheadBeat: _previewTransport.clipLocalBeat,
                      onVirtualPlayheadSeek: _previewTransport.seekClipLocal,
                      previewPlaying: _previewTransport.isPlaying,
                      onPreviewPlayRequested: _startPreviewPlay,
                      onPreviewStopRequested: _stopPreviewPlay,
                      onNotePreview: (note, {hold = false}) {
                        unawaited(_noteAudition.preview(note, hold: hold));
                      },
                      onNotePreviewEnd: () {
                        unawaited(_noteAudition.release());
                      },
                      onPitchPreview: (pitch) {
                        unawaited(
                          _noteAudition.preview(
                            MidiNoteSnapshot(
                              pitch: pitch,
                              startBeat: 0,
                              durationBeats: 0.25,
                              velocity: 100,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_showTakes && _takes.isNotEmpty)
                ListenableBuilder(
                  listenable: _previewTransport,
                  builder: (context, _) {
                    if (_compFlattened) {
                      return const MidiCompLockedBar();
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_compTool == MidiCompTool.markers)
                          MidiCompContextBar(
                            playheadBeat: _previewTransport.clipLocalBeat,
                            selectedMarkerBeat: _selectedTakeMarkerBeat,
                            holdPrevious: _selectedTakeMarkerHold,
                            onSplitAtPlayhead: _splitMidiTakeAtPlayhead,
                            onDeleteSelected: _deleteSelectedMidiTakeMarker,
                            onNudgeSelected: _nudgeSelectedMidiTakeMarker,
                            onMarkerModeChanged: _setSelectedMidiTakeMarkerMode,
                          )
                        else if (_compTool == MidiCompTool.comp)
                          MidiCompRegionBar(
                            playheadBeat: _previewTransport.clipLocalBeat,
                            takes: _takes,
                            regions: _takeRegions,
                          ),
                        MidiCompToolDock(
                          tool: _compTool,
                          previewPlaying: _previewTransport.isPlaying,
                          onToolChanged: (tool) {
                            setState(() {
                              _compTool = tool;
                              if (tool == MidiCompTool.markers) {
                                _selectedTakeMarker = null;
                              }
                            });
                            unawaited(
                              MidiCompModeHints.maybeShow(context, tool),
                            );
                          },
                          onPreviewPlayStop: _togglePreviewPlay,
                        ),
                      ],
                    );
                  },
                ),
              if (!_showTakes) ...[
                PianoRollToolDock(
                  tool: _tool,
                  canUndo: _undoStack.isNotEmpty,
                  canRedo: _redoStack.isNotEmpty,
                  previewPlaying: _previewTransport.isPlaying,
                  onPreviewPlayStop: _togglePreviewPlay,
                  onToolChanged: (tool) => setState(() => _tool = tool),
                  onEditTap: _openEditSheet,
                  onUndo: _undo,
                  onRedo: _redo,
                  editorMode: _editorMode,
                  canUseDrumMode: widget.drumLaneLayout != null,
                  onEditorModeChanged: (mode) => setState(() {
                    _editorMode = mode;
                    _selectedIndex = null;
                    if (mode == MidiEditorMode.drums) {
                      _toolMode = PianoRollCenterMode.notes;
                    }
                  }),
                  onDrawSettings: _openDrawSheet,
                  hideNoteTools: _isHarmonyTool,
                ),
                PlayDeck(
                  bridge: widget.bridge,
                  initialSurfaceMode: PlaySurfaceMode.keys,
                  initialOctaveOffset: _initialOctaveOffset,
                  padPitchBase: widget.drumAnchorPitch,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
