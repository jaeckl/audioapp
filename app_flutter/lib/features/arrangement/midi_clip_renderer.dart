import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../bridge/project_snapshot.dart';
import 'arrangement_clip_beat_layout.dart';
import 'arrangement_clip_loop_visual.dart';
import 'arrangement_clip_theme.dart';
import 'clip_renderer.dart';

/// Condensed mini piano-roll preview for arrangement MIDI clips.
class MidiClipRenderer extends ClipRenderer {
  const MidiClipRenderer(this.clip);

  final MidiClipSnapshot clip;

  static const double _minNoteWidthPx = 1;
  static const double _minNoteHeightPx = 1;
  static const double _verticalPaddingPx = 1.5;

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

    final inner = Rect.fromLTRB(
      contentRect.left,
      contentRect.top + _verticalPaddingPx,
      contentRect.right,
      contentRect.bottom - _verticalPaddingPx,
    );
    if (inner.width <= 0 || inner.height <= 0) return;

    final contentLength = _contentLengthBeats;
    final looping = clip.loopContent &&
        contentLength > 0 &&
        clip.lengthBeats > contentLength;

    if (looping) {
      ArrangementClipLoopVisual.paintRepeatRegions(
        canvas: canvas,
        contentRect: contentRect,
        contentLengthBeats: contentLength,
        clipLengthBeats: clip.lengthBeats,
        lengthBeats: clip.lengthBeats,
      );
    }

    var minPitch = notes.first.pitch;
    var maxPitch = notes.first.pitch;
    for (final note in notes) {
      minPitch = math.min(minPitch, note.pitch);
      maxPitch = math.max(maxPitch, note.pitch);
    }

    final pitchSpan = math.max(1, maxPitch - minPitch + 1);
    final rowHeight = inner.height / pitchSpan;
    final pixelsPerBeat = ArrangementClipBeatLayout.pixelsPerBeat(
      contentRect: contentRect,
      lengthBeats: clip.lengthBeats,
    );

    final fill = Paint()..color = ArrangementClipTheme.midiNoteFill;
    final repeatFill = Paint()..color = ArrangementClipTheme.midiNoteFillRepeat;
    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    void paintNotesInTile(double tileOriginBeat, {required bool isRepeat}) {
      final noteFill = isRepeat ? repeatFill : fill;
      for (final note in notes) {
        final left = ArrangementClipBeatLayout.beatToX(
          beat: tileOriginBeat + note.startBeat,
          contentRect: contentRect,
          lengthBeats: clip.lengthBeats,
        );
        final width = math.max(
          _minNoteWidthPx,
          note.durationBeats * pixelsPerBeat,
        );
        final top = inner.top + (maxPitch - note.pitch) * rowHeight;
        final height = math.max(_minNoteHeightPx, rowHeight - 0.5);

        final noteRect = Rect.fromLTWH(left, top, width, height);
        if (!noteRect.overlaps(inner)) continue;

        final clipped = noteRect.intersect(inner);
        final radius = Radius.circular(math.min(2, clipped.height / 2));
        canvas.drawRRect(RRect.fromRectAndRadius(clipped, radius), noteFill);
        if (clipped.width > 2 && clipped.height > 2) {
          canvas.drawRRect(RRect.fromRectAndRadius(clipped, radius), border);
        }
      }
    }

    if (looping) {
      for (var tileOriginBeat = 0.0;
          tileOriginBeat < clip.lengthBeats;
          tileOriginBeat += contentLength) {
        paintNotesInTile(tileOriginBeat, isRepeat: tileOriginBeat > 0);
      }
      return;
    }

    paintNotesInTile(0, isRepeat: false);
  }
}
