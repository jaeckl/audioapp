part of 'midi_take_comp_view.dart';

class _MidiTakeLanePainter extends CustomPainter {
  const _MidiTakeLanePainter({
    required this.notes,
    required this.regions,
    required this.activeTakeId,
    required this.pitchRows,
    required this.clipLengthBeats,
    required this.virtualLengthBeats,
    required this.notesTop,
    required this.pixelsPerBeat,
    required this.pitchRowHeight,
  });

  final List<MidiNoteSnapshot> notes;
  final List<MidiClipTakeRegionSnapshot> regions;
  final String? activeTakeId;
  final List<int> pitchRows;
  final double clipLengthBeats;
  final double virtualLengthBeats;
  final double notesTop;
  final double pixelsPerBeat;
  final double pitchRowHeight;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintCompRegions(canvas, size);
    _paintGrid(canvas, size);
    _paintNotes(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final clipWidth = clipLengthBeats * pixelsPerBeat;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, clipWidth, size.height),
      Paint()..color = const Color(0xFF17171C),
    );
    if (clipWidth < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(clipWidth, 0, size.width - clipWidth, size.height),
        Paint()..color = const Color(0xAA09090C),
      );
    }
  }

  void _paintCompRegions(Canvas canvas, Size size) {
    if (activeTakeId == null || clipLengthBeats <= 0) return;
    final active = Paint()
      ..color = ArrangementLoopRegionTheme.color.withValues(alpha: 0.10);
    final border = Paint()
      ..color = ArrangementLoopRegionTheme.color.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final region in regions) {
      if (region.takeId != activeTakeId) continue;
      final left = region.startBeat * pixelsPerBeat;
      final right = region.endBeat * pixelsPerBeat;
      if (right <= left) continue;
      final rect = Rect.fromLTRB(left, 6, right, size.height - 6);
      final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(7));
      canvas.drawRRect(rounded, active);
      canvas.drawRRect(rounded, border);
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final beat = Paint()
      ..color = const Color(0x12FFFFFF)
      ..strokeWidth = 0.5;
    final bar = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    final row = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 0.5;
    for (var b = 0.0; b <= virtualLengthBeats; b += 1.0) {
      final x = b * pixelsPerBeat;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        b % PianoRollMetrics.beatsPerBar == 0 ? bar : beat,
      );
    }
    for (var i = 0; i <= pitchRows.length; i++) {
      final y = notesTop + i * pitchRowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), row);
    }
  }

  void _paintNotes(Canvas canvas, Size size) {
    final pitchIndex = {
      for (final entry in pitchRows.indexed) entry.$2: entry.$1
    };
    final fill = Paint()
      ..color = const Color(0xFF818AA4).withValues(alpha: 0.62);
    final stroke = Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (final note in notes) {
      final row = pitchIndex[note.pitch];
      if (row == null) continue;
      final rect = Rect.fromLTWH(
        note.startBeat * pixelsPerBeat,
        notesTop + row * pitchRowHeight + 2,
        math.max(2.0, note.durationBeats * pixelsPerBeat),
        math.max(5.0, pitchRowHeight - 4),
      );
      final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(rounded, fill);
      canvas.drawRRect(rounded, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MidiTakeLanePainter oldDelegate) {
    return oldDelegate.notes != notes ||
        oldDelegate.regions != regions ||
        oldDelegate.activeTakeId != activeTakeId ||
        oldDelegate.pitchRows != pitchRows ||
        oldDelegate.clipLengthBeats != clipLengthBeats ||
        oldDelegate.virtualLengthBeats != virtualLengthBeats ||
        oldDelegate.notesTop != notesTop ||
        oldDelegate.pixelsPerBeat != pixelsPerBeat ||
        oldDelegate.pitchRowHeight != pitchRowHeight;
  }
}
