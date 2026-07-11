part of 'curve_editor_screen.dart';

class _CurveEditorPainter extends CustomPainter {
  _CurveEditorPainter({
    required this.positions,
    required this.values,
    required this.shapes,
    required this.polarity,
    required this.highlightedIndex,
    required this.selectedIndices,
    required this.shapeHighlightStart,
    required this.shapeHighlightEnd,
    required this.accent,
  });

  final List<double> positions;
  final List<double> values;
  final List<int> shapes;
  final int polarity;
  final int? highlightedIndex;
  final Set<int> selectedIndices;
  final double? shapeHighlightStart;
  final double? shapeHighlightEnd;
  final Color accent;

  static const int _hermiteSteps = 20;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A24),
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var i = 1; i < _gridDivisions; i++) {
      final x = size.width * i / _gridDivisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (polarity == 0) {
      final cy = size.height / 2;
      canvas.drawLine(
        Offset(0, cy),
        Offset(size.width, cy),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..strokeWidth = 0.5,
      );
    }

    final shapeStart = shapeHighlightStart;
    final shapeEnd = shapeHighlightEnd;
    if (shapeStart != null && shapeEnd != null) {
      final left = math.min(shapeStart, shapeEnd) * size.width;
      final right = math.max(shapeStart, shapeEnd) * size.width;
      final region = Rect.fromLTRB(left, 0, right, size.height);
      canvas.drawRect(
        region,
        Paint()..color = accent.withValues(alpha: 0.1),
      );
      canvas.drawRect(
        region,
        Paint()
          ..color = accent.withValues(alpha: 0.65)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    // Highlight region between two selected points.
    if (selectedIndices.length == 2) {
      final sorted = selectedIndices.toList()
        ..sort((a, b) => positions[a].compareTo(positions[b]));
      final sx = positions[sorted[0]] * size.width;
      final ex = positions[sorted[1]] * size.width;
      canvas.drawRect(
        Rect.fromLTRB(sx, 0, ex, size.height),
        Paint()..color = accent.withValues(alpha: 0.08),
      );
      canvas.drawLine(
          Offset(sx, 0),
          Offset(sx, size.height),
          Paint()
            ..color = accent.withValues(alpha: 0.3)
            ..strokeWidth = 1.5);
      canvas.drawLine(
          Offset(ex, 0),
          Offset(ex, size.height),
          Paint()
            ..color = accent.withValues(alpha: 0.3)
            ..strokeWidth = 1.5);
    }

    final count = positions.length;
    if (count < 2) return;

    final zeroY = polarity == 0 ? size.height / 2 : size.height;
    final curvePath = Path();
    final fillPath = Path();

    double px = positions[0].clamp(0.0, 1.0) * size.width;
    double py = size.height * (0.5 - values[0].clamp(-1.0, 1.0) * 0.5);
    curvePath.moveTo(px, py);
    fillPath.moveTo(px, py);

    for (var i = 0; i < count - 1; i++) {
      final x1 = positions[i + 1].clamp(0.0, 1.0) * size.width;
      final y1 = size.height * (0.5 - values[i + 1].clamp(-1.0, 1.0) * 0.5);
      final shape = i < shapes.length ? shapes[i] : 0;

      switch (shape) {
        case 0:
          curvePath.lineTo(x1, y1);
          fillPath.lineTo(x1, y1);
        case 1:
          final v0 = values[i];
          final v1 = values[i + 1];
          final m = (v1 - v0) * 0.5;
          final segWidth = x1 - px;
          for (var s = 1; s <= _hermiteSteps; s++) {
            final t = s / _hermiteSteps;
            final t2 = t * t;
            final t3 = t2 * t;
            final v = 2 * t3 * v0 -
                3 * t2 * v0 +
                v0 +
                t3 * m -
                2 * t2 * m +
                t * m +
                -2 * t3 * v1 +
                3 * t2 * v1 +
                t3 * m -
                t2 * m;
            final ix = px + segWidth * t;
            final iy = size.height * (0.5 - v * 0.5);
            curvePath.lineTo(ix, iy);
            fillPath.lineTo(ix, iy);
          }
        case 2:
          curvePath.lineTo(x1, py);
          curvePath.lineTo(x1, y1);
          fillPath.lineTo(x1, py);
          fillPath.lineTo(x1, y1);
      }
      px = x1;
      py = y1;
    }

    final lastX = positions[count - 1].clamp(0.0, 1.0) * size.width;
    final firstX = positions[0].clamp(0.0, 1.0) * size.width;
    fillPath.lineTo(lastX, zeroY);
    fillPath.lineTo(firstX, zeroY);
    fillPath.close();

    canvas.drawPath(
        fillPath,
        Paint()
          ..color = accent.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill);
    canvas.drawPath(
        curvePath,
        Paint()
          ..color = accent.withValues(alpha: 0.9)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    for (var i = 0; i < count; i++) {
      final x = positions[i].clamp(0.0, 1.0) * size.width;
      final y = size.height * (0.5 - values[i].clamp(-1.0, 1.0) * 0.5);
      final isSel = selectedIndices.contains(i);
      final isDrag = highlightedIndex == i;
      final r = (isSel || isDrag) ? _selectedDotRadius : _dotRadius;
      final dotColor =
          (isSel || isDrag) ? accent : accent.withValues(alpha: 0.7);
      canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = dotColor
            ..style = PaintingStyle.fill);
      if (isSel || isDrag) {
        canvas.drawCircle(
            Offset(x, y),
            r,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
    }

    for (var i = 0; i < count - 1; i++) {
      final s = i < shapes.length ? shapes[i] : 0;
      final label = ['L', 'S', 'H'][s.clamp(0, 2)];
      final mx = (positions[i] + positions[i + 1]) / 2 * size.width;
      final midV = (values[i] + values[i + 1]) / 2;
      final my = size.height * (0.5 - midV * 0.5);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 9,
              fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(mx - tp.width / 2, my - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_CurveEditorPainter old) {
    if (old.positions.length != positions.length) return true;
    for (var i = 0; i < positions.length; i++) {
      if (old.positions[i] != positions[i] ||
          old.values[i] != values[i] ||
          old.shapes[i] != shapes[i]) {
        return true;
      }
    }
    return old.polarity != polarity ||
        old.highlightedIndex != highlightedIndex ||
        old.shapeHighlightStart != shapeHighlightStart ||
        old.shapeHighlightEnd != shapeHighlightEnd ||
        old.selectedIndices.length != selectedIndices.length ||
        !old.selectedIndices.every(selectedIndices.contains) ||
        old.accent != accent;
  }
}
