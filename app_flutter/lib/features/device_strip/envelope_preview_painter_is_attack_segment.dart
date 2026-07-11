part of 'envelope_preview_painter.dart';

extension _EnvelopePreviewPainterIsattacksegment on EnvelopePreviewPainter {
  bool _isAttackSegment(int segStartIdx, List<Offset> pts, bool hasDelay) {
    final attackIdx = hasDelay ? 1 : 0;
    return segStartIdx == attackIdx;
  }
}
