part of 'envelope_preview_painter.dart';

extension _EnvelopePreviewPainterIssustainnode on EnvelopePreviewPainter {
  bool _isSustainNode(int index, List<Offset> pts) {
    if (index <= 0 || index >= pts.length - 1) return false;
    final dy = pts[index].dy;
    return dy > 2 && dy < pts[0].dy - 2;
  }
}
