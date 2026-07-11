part of 'envelope_preview_painter.dart';

extension _EnvelopePreviewPainterIsreleasesegment on EnvelopePreviewPainter {
  bool _isReleaseSegment(int segStartIdx, List<Offset> pts) {
    return segStartIdx == pts.length - 2;
  }
}
