part of 'piano_roll_screen.dart';

extension _PianoRollScreenStateHarmonicMode on _PianoRollScreenState {
  PianoRollCenterMode get _centerMode {
    if (_showTakes && _takes.isNotEmpty) return PianoRollCenterMode.comp;
    return _toolMode;
  }

  bool get _isHarmonyTool =>
      _toolMode == PianoRollCenterMode.harmonic ||
      _toolMode == PianoRollCenterMode.progression ||
      _toolMode == PianoRollCenterMode.rhythm;

  bool get _showHarmonyInsert =>
      _toolMode == PianoRollCenterMode.harmonic ||
      _toolMode == PianoRollCenterMode.progression;

  List<ChordSlot>? get _slotsOrNull =>
      _chordSlots.isEmpty ? null : _chordSlots;

  void _onCenterModeChanged(PianoRollCenterMode mode) {
    setState(() {
      switch (mode) {
        case PianoRollCenterMode.notes:
          _showTakes = false;
          _toolMode = PianoRollCenterMode.notes;
          _harmonyChordSelected = true;
        case PianoRollCenterMode.harmonic:
          _showTakes = false;
          _toolMode = PianoRollCenterMode.harmonic;
          _harmonyChordSelected = true;
        case PianoRollCenterMode.progression:
          _showTakes = false;
          _toolMode = PianoRollCenterMode.progression;
          _harmonyChordSelected = true;
          _ensureProgressionSelection();
        case PianoRollCenterMode.rhythm:
          _showTakes = false;
          _toolMode = PianoRollCenterMode.rhythm;
          _harmonyChordSelected = true;
          _ensureRhythmSelection();
          _ensureChordSlots();
        case PianoRollCenterMode.pattern:
          _showTakes = false;
          _toolMode = PianoRollCenterMode.pattern;
          _harmonyChordSelected = true;
        case PianoRollCenterMode.groove:
          _showTakes = false;
          _toolMode = PianoRollCenterMode.groove;
          _harmonyChordSelected = true;
        case PianoRollCenterMode.fill:
          _showTakes = false;
          _toolMode = PianoRollCenterMode.fill;
          _harmonyChordSelected = true;
        case PianoRollCenterMode.comp:
          _toolMode = PianoRollCenterMode.notes;
          _harmonyChordSelected = true;
          _showTakes = true;
          _compTool = MidiCompTool.comp;
      }
    });
    if (mode == PianoRollCenterMode.comp) {
      unawaited(MidiCompModeHints.maybeShow(context, MidiCompTool.comp));
    }
  }

  void _ensureProgressionSelection() {
    final subs = RhythmSubgenre.forGenre(_progressionGenre);
    if (subs.isEmpty) return;
    if (!subs.any((s) => s.id == _progressionSubgenreId)) {
      _progressionSubgenreId = subs.first.id;
    }
    final list = ProgressionTemplate.forSubgenre(_progressionSubgenreId);
    if (list.isEmpty) return;
    if (!list.any((t) => t.id == _progressionTemplateId)) {
      _progressionTemplateId = list.first.id;
    }
  }

  void _ensureRhythmSelection() {
    final subs = RhythmSubgenre.forGenre(_rhythmGenre);
    if (subs.isEmpty) return;
    if (!subs.any((s) => s.id == _rhythmSubgenreId)) {
      _rhythmSubgenreId = subs.first.id;
    }
    final rhythms = ChordRhythmPreset.forSubgenre(_rhythmSubgenreId);
    if (rhythms.isEmpty) return;
    if (!rhythms.any((r) => r.id == _rhythmPresetId)) {
      _rhythmPresetId = rhythms.first.id;
    }
  }

  void _ensureChordSlots() {
    if (_chordSlots.isEmpty && _notes.isNotEmpty) {
      _chordSlots = HarmonicNoteOps.slotsFromNotes(_notes);
    } else {
      _chordSlots = HarmonicNoteOps.pruneSlots(_chordSlots, _notes);
    }
  }

  void _onHarmonicDegreeTap(int degree) {
    HapticFeedback.selectionClick();
    setState(() => _armedDegree = degree);

    final selected = _selectedIndex;
    if (selected != null && selected >= 0 && selected < _notes.length) {
      final group = HarmonicNoteOps.groupIndices(
        _notes,
        selected,
        slots: _slotsOrNull,
      );
      final regions = HarmonicNoteOps.chordRegions(
        _notes,
        slots: _slotsOrNull,
      );
      var start = _notes[selected].startBeat;
      var dur = HarmonicNoteOps.groupDuration(_notes, group);
      for (final r in regions) {
        if (r.noteIndices.any(group.contains)) {
          start = r.startBeat;
          dur = r.durationBeats;
          break;
        }
      }
      final replacement = HarmonicNoteOps.chordNotes(
        scale: _scale.scale,
        rootPitchClass: _scale.rootPitchClass,
        degree: degree,
        startBeat: start,
        durationBeats: dur,
        params: _harmonicParams,
      );
      final merged = HarmonicNoteOps.replaceGroup(
        existing: _notes,
        groupIndices: group,
        replacement: replacement,
      );
      _applyNotes(merged, selectedIndex: null);
      unawaited(_auditionDegree(degree));
      return;
    }
    unawaited(_auditionDegree(degree));
  }

  Future<void> _auditionDegree(int degree) async {
    final notes = HarmonicNoteOps.chordNotes(
      scale: _scale.scale,
      rootPitchClass: _scale.rootPitchClass,
      degree: degree,
      startBeat: 0,
      durationBeats: 1,
      params: _harmonicParams,
    );
    try {
      await widget.bridge.previewMidi(
        notes: notes,
        lengthBeats: 1,
        bpm: widget.bpm,
        loop: false,
      );
    } catch (_) {}
  }

  void _insertArmedChordAtNextEmpty() {
    final at = HarmonicNoteOps.nextEmptyStart(_notes, slots: _slotsOrNull);
    final duration = _grid.insertNoteDurationBeats;
    final added = HarmonicNoteOps.chordNotes(
      scale: _scale.scale,
      rootPitchClass: _scale.rootPitchClass,
      degree: _armedDegree,
      startBeat: at,
      durationBeats: duration,
      params: _harmonicParams,
    );
    _commitInsertedNotes(added, slotStart: at, beatsPerChord: duration);
  }

  void _insertSelectedProgressionAtNextEmpty() {
    final template = ProgressionTemplate.byId(_progressionTemplateId);
    final at = HarmonicNoteOps.nextEmptyStart(_notes, slots: _slotsOrNull);
    final duration = _grid.insertNoteDurationBeats;
    final added = HarmonicNoteOps.progressionNotes(
      scale: _scale.scale,
      rootPitchClass: _scale.rootPitchClass,
      template: template,
      startBeat: at,
      params: _harmonicParams,
      beatsPerChord: duration,
    );
    _commitInsertedNotes(
      added,
      slotStart: at,
      beatsPerChord: duration,
      chordCount: template.degrees.length,
    );
  }

  void _onRollPlusTap() {
    if (_toolMode == PianoRollCenterMode.harmonic) {
      _insertArmedChordAtNextEmpty();
    } else if (_toolMode == PianoRollCenterMode.progression) {
      _insertSelectedProgressionAtNextEmpty();
    }
  }

  void _onRhythmChanged(String rhythmId) {
    _ensureChordSlots();
    final slots = _chordSlots.isEmpty
        ? HarmonicNoteOps.slotsFromNotes(_notes)
        : _chordSlots;
    final preset = ChordRhythmPreset.byId(rhythmId);
    if (slots.isEmpty) {
      setState(() => _rhythmPresetId = rhythmId);
      return;
    }
    final next = HarmonicNoteOps.applyRhythm(
      notes: _notes,
      slots: slots,
      preset: preset,
    );
    setState(() {
      _rhythmPresetId = rhythmId;
      _chordSlots = slots;
    });
    _applyNotes(next, selectedIndex: null);
  }

  void _commitInsertedNotes(
    List<MidiNoteSnapshot> added, {
    required double slotStart,
    required double beatsPerChord,
    int chordCount = 1,
  }) {
    if (added.isEmpty) return;
    final merged = HarmonicNoteOps.insertNotes(existing: _notes, added: added);
    final newSlots = [
      ..._chordSlots,
      for (var i = 0; i < chordCount; i++)
        ChordSlot(
          startBeat: slotStart + i * beatsPerChord,
          endBeat: slotStart + (i + 1) * beatsPerChord,
        ),
    ]..sort((a, b) => a.startBeat.compareTo(b.startBeat));
    final newLength = HarmonicAssistantCommit.requiredClipLength(
      currentLength: _clipLengthBeats,
      notes: merged,
    );
    setState(() => _chordSlots = newSlots);
    _applyNotes(merged, selectedIndex: null);
    if (newLength > _clipLengthBeats + 1e-9) {
      setState(() {
        _clipLengthBeats = newLength;
        _previewTransport.maxClipBeat = newLength;
      });
      unawaited(_persistClipLength());
    }
  }
}
