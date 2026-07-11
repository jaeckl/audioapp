part of 'envelope_preview_painter.dart';

extension _EnvelopePreviewPainterIscurvablesegment on EnvelopePreviewPainter {
  bool _isCurvableSegment(int segStartIdx, List<Offset> pts, bool hasDelay,
      bool hasHold, bool hasDecay) {
    // Attack: first segment after delay (or the very first segment if no delay)
    // Decay: the segment ending at sustain level
    // Release: last segment
    // A segment is curvable if it's not flat (start y ≠ end y)
    if (segStartIdx + 1 >= pts.length) return false;
    if (pts[segStartIdx].dy == pts[segStartIdx + 1].dy) return false;

    // Skip flat hold segment (AHDSR)
    if (hasHold) {
      final holdIdx = (hasDelay ? 2 : 1);
      if (segStartIdx == holdIdx) return false; // hold is flat
    }
    // Skip sustain flat segment
    if (segStartIdx == pts.length - 2)
      return true; // release is always curvable
    if (segStartIdx >= 0 && segStartIdx < pts.length - 2)
      return true; // attack, decay, or other middle segment
    return false;
  }
}
