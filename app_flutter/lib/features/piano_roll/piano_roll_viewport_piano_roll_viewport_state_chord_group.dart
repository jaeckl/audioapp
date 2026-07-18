part of 'piano_roll_viewport.dart';

extension _PianoRollViewportStateChordgroup on PianoRollViewportState {
  List<ChordSlot>? get _slotsOrNull =>
      widget.chordSlots.isEmpty ? null : widget.chordSlots;

  List<int> _chordGroupFor(int index) {
    if (!widget.chordGroupEdit) return [index];
    return HarmonicNoteOps.groupIndices(
      widget.notes,
      index,
      slots: _slotsOrNull,
    );
  }

  List<int> get _highlightedChordIndices {
    if (_dragGroupIndexes.isNotEmpty) return _dragGroupIndexes;
    final i = widget.selectedIndex;
    if (!widget.chordGroupEdit || i == null) return const [];
    if (!widget.chordGroupSelected) return [i];
    return _chordGroupFor(i);
  }

  void _captureDragGroup(int primaryIndex, {required bool asChord}) {
    final indexes =
        asChord ? _chordGroupFor(primaryIndex) : <int>[primaryIndex];
    _dragAsChord = asChord;
    _dragGroupIndexes = indexes;
    if (asChord && indexes.isNotEmpty) {
      final regions = HarmonicNoteOps.chordRegions(
        widget.notes,
        slots: _slotsOrNull,
      );
      ChordRegion? region;
      for (final r in regions) {
        if (r.noteIndices.any(indexes.contains)) {
          region = r;
          break;
        }
      }
      if (region != null) {
        _dragStartBeat = region.startBeat;
        _dragStartDuration = region.durationBeats;
        _dragStartBeats = {
          for (final i in indexes) i: region.startBeat,
        };
        _dragStartDurations = {
          for (final i in indexes) i: region.durationBeats,
        };
      } else {
        _dragStartBeats = {
          for (final i in indexes) i: widget.notes[i].startBeat,
        };
        _dragStartDurations = {
          for (final i in indexes) i: widget.notes[i].durationBeats,
        };
      }
    } else {
      _dragStartBeats = {
        for (final i in indexes) i: widget.notes[i].startBeat,
      };
      _dragStartDurations = {
        for (final i in indexes) i: widget.notes[i].durationBeats,
      };
    }
    _dragStartPitches = {
      for (final i in indexes) i: widget.notes[i].pitch,
    };
    _dragStartAllNotes = [
      for (final n in widget.notes)
        MidiNoteSnapshot(
          pitch: n.pitch,
          startBeat: n.startBeat,
          durationBeats: n.durationBeats,
          velocity: n.velocity,
        ),
    ];
    _dragStartSlots = [
      for (final s in widget.chordSlots)
        ChordSlot(startBeat: s.startBeat, endBeat: s.endBeat),
    ];
  }
}
