part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateDrumTools on _PianoRollScreenState {
  bool get _isDrumTool =>
      _toolMode == PianoRollCenterMode.pattern ||
      _toolMode == PianoRollCenterMode.groove ||
      _toolMode == PianoRollCenterMode.fill;

  int? _initialDrumPitch() {
    final layout = widget.drumLaneLayout;
    if (layout != null) {
      for (final lane in layout.lanes) {
        if (lane.enabled) return lane.pitch;
      }
      if (layout.lanes.isNotEmpty) return layout.lanes.first.pitch;
    }
    return widget.drumAnchorPitch;
  }

  void _selectDrumPitch(int pitch) {
    if (_selectedDrumPitch == pitch) return;
    setState(() => _selectedDrumPitch = pitch);
  }

  int get _drumTargetPitch {
    if (_selectedDrumPitch != null) return _selectedDrumPitch!;
    return DrumNoteOps.resolveTargetPitch(
      notes: _notes,
      selectedIndex: _selectedIndex,
      fallbackPitch: _initialDrumPitch(),
    );
  }

  String get _drumLaneLabel {
    final pitch = _drumTargetPitch;
    final layout = widget.drumLaneLayout;
    if (layout != null) {
      for (final lane in layout.lanes) {
        if (lane.pitch == pitch && lane.name.isNotEmpty) return lane.name;
      }
    }
    return PianoRollMetrics.noteLabel(pitch);
  }

  List<int> get _drumFillPitches {
    final layout = widget.drumLaneLayout;
    if (layout != null) {
      final enabled = [
        for (final l in layout.lanes)
          if (l.enabled) l.pitch,
      ];
      if (enabled.isNotEmpty) return enabled;
    }
    if (widget.drumAnchorPitch != null) return [widget.drumAnchorPitch!];
    final fromNotes = {for (final n in _notes) n.pitch}.toList()..sort();
    if (fromNotes.isNotEmpty) return fromNotes;
    return const [42, 38, 36]; // hat, snare, kick GM defaults
  }

  void _applyDrumNotes(List<MidiNoteSnapshot> next) {
    _pushUndo();
    _applyNotes(next, selectedIndex: null);
  }

  void _onDrumApplyEuclidean() {
    _applyDrumNotes(
      DrumNoteOps.applyEuclidean(
        notes: _notes,
        pitch: _drumTargetPitch,
        lengthBeats: _clipLengthBeats,
        hits: _drumHits,
        steps: _drumSteps,
        rotate: _drumRotate,
        stepBeats: _drumStepBeats,
      ),
    );
  }

  void _onDrumRotateLane(int deltaSteps) {
    _applyDrumNotes(
      DrumNoteOps.rotateLane(
        notes: _notes,
        pitch: _drumTargetPitch,
        lengthBeats: _clipLengthBeats,
        steps: deltaSteps,
        stepBeats: _drumStepBeats,
      ),
    );
  }

  void _onDrumClearLane() {
    _applyDrumNotes(
      DrumNoteOps.clearLane(
        notes: _notes,
        pitch: _drumTargetPitch,
        lengthBeats: _clipLengthBeats,
      ),
    );
  }

  void _onDrumDice() {
    _applyDrumNotes(
      DrumNoteOps.applyProbability(
        notes: _notes,
        probability: _drumProbability,
        pitch: _drumTargetPitch,
      ),
    );
  }

  void _onDrumRatchet() {
    _applyDrumNotes(
      DrumNoteOps.applyRatchet(
        notes: _notes,
        ratchet: _drumRatchet,
        pitch: _drumTargetPitch,
      ),
    );
  }

  void _onDrumHumanize() {
    _applyDrumNotes(
      DrumNoteOps.humanizeVelocity(
        notes: _notes,
        range: _drumHumanize,
        pitch: _drumTargetPitch,
      ),
    );
  }

  void _onDrumApplyFill() {
    _applyDrumNotes(
      DrumNoteOps.applyFill(
        notes: _notes,
        lengthBeats: _clipLengthBeats,
        fillLengthBeats: _drumFillLengthBeats,
        fillPitches: _drumFillPitches,
        intensity: _drumFillIntensity,
        style: _drumFillStyle,
        seed: DateTime.now().microsecondsSinceEpoch,
      ),
    );
  }
}
