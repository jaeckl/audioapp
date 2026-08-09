import 'package:audioapp/bridge/clip_snapshots.dart';
import 'package:audioapp/features/piano_roll/midi_take_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const take1 = MidiClipTakeSnapshot(
    id: 't1',
    name: 'Take 1',
    startBeatOffset: 0,
    lengthBeats: 8,
    notes: [
      MidiNoteSnapshot(pitch: 60, startBeat: 0, durationBeats: 1, velocity: 100),
      MidiNoteSnapshot(pitch: 62, startBeat: 4, durationBeats: 1, velocity: 100),
    ],
  );
  const take2 = MidiClipTakeSnapshot(
    id: 't2',
    name: 'Take 2',
    startBeatOffset: 0,
    lengthBeats: 8,
    notes: [
      MidiNoteSnapshot(pitch: 64, startBeat: 4, durationBeats: 1, velocity: 100),
    ],
  );
  const regions = [
    MidiClipTakeRegionSnapshot(
      startBeat: 0,
      endBeat: 4,
      takeId: 't1',
      sourceStart: 0,
    ),
    MidiClipTakeRegionSnapshot(
      startBeat: 4,
      endBeat: 8,
      takeId: 't2',
      sourceStart: 4,
    ),
  ];

  test('palette cycles by take index', () {
    expect(MidiTakeColor.forIndex(0), MidiTakeColor.palette[0]);
    expect(MidiTakeColor.forIndex(8), MidiTakeColor.palette[0]);
    expect(
      MidiTakeColor.forTakeId('t2', [take1, take2]),
      MidiTakeColor.palette[1],
    );
  });

  test('regionAtBeat picks owning take', () {
    expect(MidiTakeColor.regionAtBeat(regions, 0)?.takeId, 't1');
    expect(MidiTakeColor.regionAtBeat(regions, 3.9)?.takeId, 't1');
    expect(MidiTakeColor.regionAtBeat(regions, 4)?.takeId, 't2');
    expect(MidiTakeColor.regionAtBeat(regions, 8)?.takeId, 't2');
  });

  test('noteWinsOnTake uses source window', () {
    expect(
      MidiTakeColor.noteWinsOnTake(
        note: take1.notes[0],
        takeId: 't1',
        regions: regions,
      ),
      isTrue,
    );
    expect(
      MidiTakeColor.noteWinsOnTake(
        note: take1.notes[1],
        takeId: 't1',
        regions: regions,
      ),
      isFalse,
    );
    expect(
      MidiTakeColor.noteWinsOnTake(
        note: take2.notes[0],
        takeId: 't2',
        regions: regions,
      ),
      isTrue,
    );
  });

  test('note fill dims losing takes', () {
    final accent = MidiTakeColor.forIndex(0);
    final win = MidiTakeColor.noteFill(accent, winning: true);
    final lose = MidiTakeColor.noteFill(accent, winning: false);
    expect(win.a, greaterThan(lose.a));
  });
}
