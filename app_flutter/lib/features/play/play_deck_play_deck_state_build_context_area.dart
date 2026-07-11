part of 'play_deck.dart';

extension PlayDeckStateBuildcontextareaOperation on PlayDeckState {
Widget _buildContextArea(PlayScale scale) {
    if (!widget.enabled) {
      return ColoredBox(
        color: PlayDeckTheme.gapColor,
        child: Center(
          child: Text(
            'Select a track',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: PlayDeckTheme.railLabel),
          ),
        ),
      );
    }

    switch (_view) {
      case PlayContextView.octave:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: OctavePanel(
              octaveOffset: _octaveOffset,
              rowCount: _keyboardRows,
              scaleId: _scaleId,
              inKeyOnly: _inKeyOnly,
              rootName: _noteNames[_rootMidi % 12],
              velocityCurve: _velocityCurve,
              quantize: _quantize,
              customScales: _customScales,
              onOctaveDelta: _onOctaveDelta,
              onRowCountChanged: (r) => setState(() => _keyboardRows = r),
              onScaleChanged: (id) => setState(() => _scaleId = id),
              onInKeyToggle: () => setState(() => _inKeyOnly = !_inKeyOnly),
              onVelocityCurveChanged: (c) => setState(() => _velocityCurve = c),
              onQuantizeChanged: (q) {
                setState(() => _quantize = q);
                _notifyPerformance();
              },
              onEditCustomScales: () => setState(() => _view = PlayContextView.scaleBuilder),
            ),
          ),
        );
      case PlayContextView.performPanel:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: PerformPanel(
              bridge: widget.bridge,
              scaleId: _scaleId,
              rootMidi: _rootMidi + _octaveOffset * 12,
              chord: _chord,
              arp: _arp,
              octaveSpan: _octaveSpan,
              rateMs: _rateMs,
              highlightedRoot: _activeRootOffset,
              onChordChanged: (q) => setState(() {
                _chord = q;
                _updateHighlights(_activeRootOffset);
              }),
              onArpChanged: (m) => setState(() => _arp = m),
              onSpanChanged: (s) => setState(() {
                _octaveSpan = s;
                _updateHighlights(_activeRootOffset);
              }),
              onRateChanged: (ms) => setState(() => _rateMs = ms),
              onKeyDown: (offset) => setState(() => _updateHighlights(offset)),
              onKeyUp: () => setState(() => _highlightedPitches.clear()),
            ),
          ),
        );
      case PlayContextView.performancePanel:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: PerformancePanel(
              latch: _latch,
              sustain: _sustain,
              repeat: _repeat,
              metronome: _metronome,
              chordMemory: _chordMemory,
              onLatchToggle: () {
                setState(() => _latch = !_latch);
                _notifyPerformance();
              },
              onSustainToggle: () => setState(() => _sustain = !_sustain),
              onRepeatToggle: () => setState(() => _repeat = !_repeat),
              onMetronomeToggle: () {
                setState(() => _metronome = !_metronome);
                _notifyPerformance();
              },
              onStoreChord: () {
                final slot = (_chordMemory.length % 8);
                final label = _chord.label;
                setState(() {
                  if (slot < _chordMemory.length) {
                    _chordMemory[slot] = ChordMemory(label: label, quality: _chord);
                  } else {
                    _chordMemory.add(ChordMemory(label: label, quality: _chord));
                  }
                });
              },
              onRecallChord: (i) {
                if (i < _chordMemory.length) {
                  setState(() {
                    _chord = _chordMemory[i].quality;
                    _updateHighlights(_activeRootOffset);
                  });
                }
              },
            ),
          ),
        );
      case PlayContextView.scaleBuilder:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ScaleBuilderPanel(
              onSave: (scale) {
                setState(() {
                  _customScales.add(scale);
                  _scaleId = scale.id;
                  _view = PlayContextView.octave;
                });
              },
            ),
          ),
        );
      case PlayContextView.perform:
        return ColoredBox(
          color: PlayDeckTheme.gapColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
            child: _surfaceMode == PlaySurfaceMode.pads
                ? MpcPadGrid(
                    bridge: widget.bridge,
                    bankOffset: _padBank,
                    pitchBase: widget.padPitchBase,
                    highlightedPitches: _highlightedPitches,
                    chokeGroupByColumn: _padChokeByColumn,
                    chokeGroupByRow: _padChokeByRow,
                    noteRepeatMs: _repeat ? _rateMs : 0,
                    velocityCurve: _velocityCurve,
                    onModulationChanged: (v) => setState(() => _modulation = v),
                    onPitchBendChanged: (v) => setState(() => _pitchBend = v),
                  )
                : PlayKeyboard(
                    bridge: widget.bridge,
                    scale: scale,
                    inKeyOnly: _inKeyOnly && scale.id != 'chromatic',
                    octaveOffset: _octaveOffset,
                    rowCount: _keyboardRows,
                    highlightedPitches: _highlightedPitches,
                    velocityCurve: _velocityCurve,
                    onModulationChanged: (v) => setState(() => _modulation = v),
                    onPitchBendChanged: (v) => setState(() => _pitchBend = v),
                  ),
          ),
        );
    }
  }
}
