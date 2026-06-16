import 'package:flutter/material.dart';

import '../../bridge/engine_bridge.dart';
import '../../bridge/project_snapshot.dart';

const double kPixelsPerBeat = 40;
const double kRowHeight = 22;
const int kMinPitch = 48;
const int kMaxPitch = 72;
const double kSnapBeats = 0.25;
const double kDefaultNoteBeats = 1.0;

class PianoRollScreen extends StatefulWidget {
  const PianoRollScreen({
    super.key,
    required this.bridge,
    required this.clip,
    required this.trackName,
    required this.bpm,
    required this.onSnapshot,
  });

  final EngineBridge bridge;
  final MidiClipSnapshot clip;
  final String trackName;
  final int bpm;
  final ValueChanged<ProjectSnapshot> onSnapshot;

  @override
  State<PianoRollScreen> createState() => _PianoRollScreenState();
}

class _PianoRollScreenState extends State<PianoRollScreen> {
  late List<MidiNoteSnapshot> _notes;
  int? _draggingIndex;
  _DragMode _dragMode = _DragMode.none;
  Offset? _dragStart;
  double? _dragStartBeat;
  double? _dragStartDuration;
  int? _dragStartPitch;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notes = List.of(widget.clip.notes);
  }

  double get _gridWidth => widget.clip.lengthBeats * kPixelsPerBeat;
  double get _gridHeight => (kMaxPitch - kMinPitch + 1) * kRowHeight;

  Future<void> _persistNotes() async {
    setState(() => _saving = true);
    try {
      final snapshot = await widget.bridge.setMidiClipNotes(
        clipId: widget.clip.id,
        notes: _notes,
      );
      widget.onSnapshot(snapshot);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _snapBeat(double beat) {
    return (beat / kSnapBeats).round() * kSnapBeats;
  }

  int _pitchFromDy(double dy) {
    final pitch = kMaxPitch - (dy / kRowHeight).floor();
    return pitch.clamp(kMinPitch, kMaxPitch);
  }

  double _beatFromDx(double dx) {
    return _snapBeat((dx / kPixelsPerBeat).clamp(0.0, widget.clip.lengthBeats - kSnapBeats));
  }

  int? _noteIndexAt(Offset local) {
    for (var i = _notes.length - 1; i >= 0; i--) {
      final note = _notes[i];
      final left = note.startBeat * kPixelsPerBeat;
      final top = (kMaxPitch - note.pitch) * kRowHeight;
      final width = note.durationBeats * kPixelsPerBeat;
      final rect = Rect.fromLTWH(left, top, width, kRowHeight);
      if (rect.contains(local)) return i;
    }
    return null;
  }

  _DragMode _dragModeAt(Offset local, int index) {
    final note = _notes[index];
    final left = note.startBeat * kPixelsPerBeat;
    final width = note.durationBeats * kPixelsPerBeat;
    if (local.dx >= left + width - 12) {
      return _DragMode.resize;
    }
    return _DragMode.move;
  }

  void _addNoteAt(Offset local) {
    final pitch = _pitchFromDy(local.dy);
    final startBeat = _beatFromDx(local.dx);
    if (startBeat + kDefaultNoteBeats > widget.clip.lengthBeats) return;

    setState(() {
      _notes.add(MidiNoteSnapshot(
        pitch: pitch,
        startBeat: startBeat,
        durationBeats: kDefaultNoteBeats,
        velocity: 100,
      ));
    });
    _persistNotes();
  }

  void _deleteNote(int index) {
    setState(() => _notes.removeAt(index));
    _persistNotes();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101018),
        title: Text('Piano roll — ${widget.trackName}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8 + topInset * 0),
            child: Text(
              'Tap grid to add · drag to move · drag right edge to resize · long-press to delete',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        for (var index = 0; index <= kMaxPitch - kMinPitch; index++)
                          Builder(
                            builder: (context) {
                              final pitch = kMaxPitch - index;
                              final isC = pitch % 12 == 0;
                              return Container(
                                height: kRowHeight,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 4),
                                color: isC ? const Color(0xFF1E1E28) : null,
                                child: Text(
                                  _pitchLabel(pitch),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Colors.white38,
                                        fontSize: 9,
                                      ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _gridWidth,
                        height: _gridHeight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) {
                            if (_noteIndexAt(details.localPosition) == null) {
                              _addNoteAt(details.localPosition);
                            }
                          },
                          onLongPressStart: (details) {
                            final index = _noteIndexAt(details.localPosition);
                            if (index != null) _deleteNote(index);
                          },
                          onPanStart: (details) {
                            final index = _noteIndexAt(details.localPosition);
                            if (index == null) return;
                            _draggingIndex = index;
                            _dragMode = _dragModeAt(details.localPosition, index);
                            _dragStart = details.localPosition;
                            _dragStartBeat = _notes[index].startBeat;
                            _dragStartDuration = _notes[index].durationBeats;
                            _dragStartPitch = _notes[index].pitch;
                          },
                          onPanUpdate: (details) {
                            final index = _draggingIndex;
                            if (index == null ||
                                _dragStart == null ||
                                _dragStartBeat == null ||
                                _dragStartDuration == null ||
                                _dragStartPitch == null) {
                              return;
                            }

                            final delta = details.localPosition - _dragStart!;
                            setState(() {
                              final note = _notes[index];
                              if (_dragMode == _DragMode.move) {
                                final newBeat = _snapBeat(
                                  (_dragStartBeat! + delta.dx / kPixelsPerBeat)
                                      .clamp(0.0, widget.clip.lengthBeats - note.durationBeats),
                                );
                                final newPitch = _pitchFromDy(
                                  (kMaxPitch - _dragStartPitch!) * kRowHeight + delta.dy,
                                );
                                _notes[index] = MidiNoteSnapshot(
                                  pitch: newPitch,
                                  startBeat: newBeat,
                                  durationBeats: note.durationBeats,
                                  velocity: note.velocity,
                                );
                              } else if (_dragMode == _DragMode.resize) {
                                final newDuration = _snapBeat(
                                  (_dragStartDuration! + delta.dx / kPixelsPerBeat)
                                      .clamp(kSnapBeats, widget.clip.lengthBeats - note.startBeat),
                                );
                                _notes[index] = MidiNoteSnapshot(
                                  pitch: note.pitch,
                                  startBeat: note.startBeat,
                                  durationBeats: newDuration,
                                  velocity: note.velocity,
                                );
                              }
                            });
                          },
                          onPanEnd: (_) {
                            if (_draggingIndex != null) _persistNotes();
                            _draggingIndex = null;
                            _dragMode = _DragMode.none;
                          },
                          child: CustomPaint(
                            painter: _PianoRollGridPainter(
                              lengthBeats: widget.clip.lengthBeats,
                              minPitch: kMinPitch,
                              maxPitch: kMaxPitch,
                            ),
                            child: Stack(
                              children: [
                                for (var i = 0; i < _notes.length; i++)
                                  _NoteBlock(
                                    note: _notes[i],
                                    selected: i == _draggingIndex,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _pitchLabel(int pitch) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final octave = (pitch ~/ 12) - 1;
    return '${names[pitch % 12]}$octave';
  }
}

enum _DragMode { none, move, resize }

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.note, required this.selected});

  final MidiNoteSnapshot note;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: note.startBeat * kPixelsPerBeat,
      top: (kMaxPitch - note.pitch) * kRowHeight + 2,
      width: note.durationBeats * kPixelsPerBeat,
      height: kRowHeight - 4,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8B7CF6) : const Color(0xFF5C6BC0),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? Colors.white : Colors.white24),
        ),
      ),
    );
  }
}

class _PianoRollGridPainter extends CustomPainter {
  _PianoRollGridPainter({
    required this.lengthBeats,
    required this.minPitch,
    required this.maxPitch,
  });

  final double lengthBeats;
  final int minPitch;
  final int maxPitch;

  @override
  void paint(Canvas canvas, Size size) {
    final beatPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    final barPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    for (var beat = 0.0; beat <= lengthBeats; beat += 0.25) {
      final x = beat * kPixelsPerBeat;
      final paint = beat % 1 == 0 ? barPaint : beatPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var pitch = minPitch; pitch <= maxPitch; pitch++) {
      final y = (maxPitch - pitch) * kRowHeight;
      final isC = pitch % 12 == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = isC ? Colors.white12 : Colors.white.withValues(alpha: 0.04),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PianoRollGridPainter oldDelegate) {
    return oldDelegate.lengthBeats != lengthBeats;
  }
}
