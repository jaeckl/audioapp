import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'arrangement_clip_theme.dart';
import 'clip_renderer.dart';

/// Condensed mini piano-roll preview for arrangement MIDI clips.
class MidiClipRenderer extends ClipRenderer {
  const MidiClipRenderer(this.clip);

  final MidiClipSnapshot clip;

  static const double _minNoteWidthPx = 1;
  static const double _minNoteHeightPx = 1;
  static const double _contentPaddingPx = 1.5;

  @override
  Color get clipBackgroundColor => ArrangementClipTheme.midiClipBackground;

  @override
  Color get clipContentBackgroundColor =>
      ArrangementClipTheme.contentBackground(clipBackgroundColor);

  @override
  bool get loopContentEnabled => clip.loopContent;

  @override
  String? get emptyPlaceholder => clip.notes.isEmpty ? 'MIDI' : null;

  double get _contentLengthBeats => clip.loopContentLengthBeats;

  @override
  void paintContent(Canvas canvas, Rect contentRect) {
    final notes = clip.notes;
    if (notes.isEmpty || clip.lengthBeats <= 0) return;

    final inner = contentRect.deflate(_contentPaddingPx);
    if (inner.width <= 0 || inner.height <= 0) return;

    var minPitch = notes.first.pitch;
    var maxPitch = notes.first.pitch;
    for (final note in notes) {
      minPitch = math.min(minPitch, note.pitch);
      maxPitch = math.max(maxPitch, note.pitch);
    }

    final pitchSpan = math.max(1, maxPitch - minPitch + 1);
    final rowHeight = inner.height / pitchSpan;
    final beatScale = inner.width / clip.lengthBeats;
    final contentLength = _contentLengthBeats;
    final tileWidthPx = contentLength * beatScale;

    final fill = Paint()..color = ArrangementClipTheme.midiNoteFill;
    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    void paintNotesInTile(double tileLeft) {
      for (final note in notes) {
        final left = tileLeft + note.startBeat * beatScale;
        final width = math.max(_minNoteWidthPx, note.durationBeats * beatScale);
        final top = inner.top + (maxPitch - note.pitch) * rowHeight;
        final height = math.max(_minNoteHeightPx, rowHeight - 0.5);

        final noteRect = Rect.fromLTWH(left, top, width, height);
        if (!noteRect.overlaps(inner)) continue;

        final clipped = noteRect.intersect(inner);
        final radius = Radius.circular(math.min(2, clipped.height / 2));
        canvas.drawRRect(RRect.fromRectAndRadius(clipped, radius), fill);
        if (clipped.width > 2 && clipped.height > 2) {
          canvas.drawRRect(RRect.fromRectAndRadius(clipped, radius), border);
        }
      }
    }

    if (clip.loopContent &&
        contentLength > 0 &&
        clip.lengthBeats > contentLength &&
        tileWidthPx > 0) {
      for (var tileLeft = inner.left;
          tileLeft < inner.right;
          tileLeft += tileWidthPx) {
        paintNotesInTile(tileLeft);
      }
      return;
    }

    paintNotesInTile(inner.left);
  }
}
