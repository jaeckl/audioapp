part of 'library_preview_widget.dart';

class MidiPreviewPainter extends CustomPainter {
  MidiPreviewPainter({
    required this.notes,
    required this.lengthBeats,
    required this.color,
  });

  final List<MidiNoteSnapshot> notes;
  final double lengthBeats;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (notes.isEmpty || lengthBeats <= 0) return;

    var minPitch = notes.first.pitch;
    var maxPitch = notes.first.pitch;
    for (final note in notes) {
      minPitch = math.min(minPitch, note.pitch);
      maxPitch = math.max(maxPitch, note.pitch);
    }

    // Centered span or minimum height window to prevent huge note blocks
    final pitchSpan = math.max(12, maxPitch - minPitch + 1);
    final centerPitch = (minPitch + maxPitch) ~/ 2;
    final viewMinPitch = centerPitch - (pitchSpan ~/ 2);
    final viewMaxPitch = viewMinPitch + pitchSpan - 1;

    final rowHeight = size.height / pitchSpan;
    final beatScale = size.width / lengthBeats;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final border = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final note in notes) {
      final x = note.startBeat * beatScale;
      final w = note.durationBeats * beatScale;
      final y = (viewMaxPitch - note.pitch) * rowHeight;
      final h = rowHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h).deflate(0.5),
        const Radius.circular(1),
      );
      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, border);
    }
  }

  @override
  bool shouldRepaint(covariant MidiPreviewPainter oldDelegate) {
    return oldDelegate.notes != notes ||
        oldDelegate.lengthBeats != lengthBeats ||
        oldDelegate.color != color;
  }
}
