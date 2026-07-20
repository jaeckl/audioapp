part of 'eq_preview.dart';

class _EqPreviewPainter extends CustomPainter {
  _EqPreviewPainter({
    required this.bands,
    required this.accent,
    required this.selectedBandIndex,
    required this.bandColors,
    this.dragIndex,
  });

  final List<EqBand> bands;
  final Color accent;
  final int selectedBandIndex;
  final List<Color> bandColors;
  final int? dragIndex;

  static const _labelStyle = TextStyle(
    color: Color(0x8CFFFFFF), // white @ ~55%
    fontSize: 8,
    fontWeight: FontWeight.w600,
    height: 1,
  );

  static const _quietLabelStyle = TextStyle(
    color: Color(0x4DFFFFFF), // white @ ~30%
    fontSize: 7,
    fontWeight: FontWeight.w600,
    height: 1,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final plot = EqPreviewGeometry.plotRect(size);
    final curve = EqPreviewGeometry.curveRect(size);
    if (curve.width <= 0 || curve.height <= 0) return;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.0;

    for (final f in const [100.0, 1000.0, 10000.0]) {
      final x = curve.left + EqPreviewGeometry.freqToX(f, curve.width);
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gridPaint);
    }
    for (double db = -24; db <= 24; db += 12) {
      final y = curve.top + EqPreviewGeometry.dbToY(db, curve.height);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    final zeroY = curve.top + EqPreviewGeometry.dbToY(0, curve.height);
    canvas.drawLine(
      Offset(plot.left, zeroY),
      Offset(plot.right, zeroY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = 1.0,
    );

    _paintScaleLabels(canvas, size, plot, curve);

    // Combined magnitude curve.
    final path = Path();
    final stepCount = math.max(80, curve.width.toInt());
    for (var i = 0; i <= stepCount; i++) {
      final t = i / stepCount;
      final x = curve.left + t * curve.width;
      final f = EqPreviewGeometry.xToFreq(t * curve.width, curve.width);
      var totalDb = 0.0;
      for (var b = 0; b < bands.length; b++) {
        totalDb += _bandDb(bands[b], b, f);
      }
      final y = curve.top + EqPreviewGeometry.dbToY(totalDb, curve.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );

    // Handles at (freq, gain) — 1:1 with params (not on combined curve).
    for (var b = 0; b < bands.length; b++) {
      final band = bands[b];
      final pos = EqPreviewGeometry.handleOffset(band, size);
      final color = b < bandColors.length ? bandColors[b] : accent;
      final selected = b == selectedBandIndex;
      final dragging = b == dragIndex;

      if (selected || dragging) {
        canvas.drawLine(
          Offset(pos.dx, plot.top),
          Offset(pos.dx, plot.bottom),
          Paint()
            ..color = color.withValues(alpha: 0.22)
            ..strokeWidth = 1.0,
        );
        canvas.drawLine(
          Offset(plot.left, pos.dy),
          Offset(plot.right, pos.dy),
          Paint()
            ..color = color.withValues(alpha: 0.18)
            ..strokeWidth = 1.0,
        );
      }

      canvas.drawCircle(
        pos,
        dragging ? 14.0 : (selected ? 11.0 : 9.0),
        Paint()..color = color.withValues(alpha: dragging ? 0.28 : 0.14),
      );
      canvas.drawCircle(
        pos,
        selected || dragging ? 6.0 : 4.5,
        Paint()
          ..color = color.withValues(alpha: selected || dragging ? 1.0 : 0.8),
      );
      canvas.drawCircle(
        pos,
        selected || dragging ? 6.0 : 4.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      if (dragging) {
        final label = '${_fmtHz(band.cutoffHz)}  ${_fmtDb(band.gainDb)}';
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final lx =
            (pos.dx - tp.width / 2).clamp(2.0, size.width - tp.width - 2);
        final ly = (pos.dy - tp.height - 10)
            .clamp(2.0, size.height - tp.height - 2);
        tp.paint(canvas, Offset(lx, ly));
      }
    }
  }

  void _paintScaleLabels(
    Canvas canvas,
    Size size,
    Rect plot,
    Rect curve,
  ) {
    // dB (left of plot).
    for (final entry in EqPreviewGeometry.dbLabels) {
      final y = curve.top + EqPreviewGeometry.dbToY(entry.$1, curve.height);
      final quiet = entry.$1 != 0.0 && entry.$1.abs() != 24.0;
      final tp = TextPainter(
        text: TextSpan(
          text: entry.$2,
          style: quiet ? _quietLabelStyle : _labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          (plot.left - tp.width - 3).clamp(0.0, size.width),
          y - tp.height / 2,
        ),
      );
    }

    // Hz (below plot).
    for (final entry in EqPreviewGeometry.freqLabels) {
      final x = curve.left + EqPreviewGeometry.freqToX(entry.$1, curve.width);
      final tp = TextPainter(
        text: TextSpan(text: entry.$2, style: _labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelX = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(labelX, plot.bottom + 3));
    }
  }

  static String _fmtHz(double hz) {
    if (hz >= 10000) return '${(hz / 1000).toStringAsFixed(1)}k';
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(2)}k';
    return '${hz.round()}Hz';
  }

  static String _fmtDb(double db) {
    final s = db.toStringAsFixed(1);
    return db >= 0 ? '+$s dB' : '$s dB';
  }

  double _bandDb(EqBand band, int index, double frequencyHz) {
    if (band.isShelf) {
      return index == 0
          ? BiquadResponse.lowShelf(
              cutoffHz: band.cutoffHz,
              q: band.q,
              gainDb: band.gainDb,
              frequencyHz: frequencyHz,
            )
          : BiquadResponse.highShelf(
              cutoffHz: band.cutoffHz,
              q: band.q,
              gainDb: band.gainDb,
              frequencyHz: frequencyHz,
            );
    }
    return BiquadResponse.peakFilter(
      cutoffHz: band.cutoffHz,
      q: band.q,
      gainDb: band.gainDb,
      frequencyHz: frequencyHz,
    );
  }

  @override
  bool shouldRepaint(covariant _EqPreviewPainter old) {
    if (old.accent != accent ||
        old.selectedBandIndex != selectedBandIndex ||
        old.bandColors != bandColors ||
        old.dragIndex != dragIndex) {
      return true;
    }
    if (old.bands.length != bands.length) return true;
    for (var i = 0; i < bands.length; i++) {
      final a = old.bands[i];
      final b = bands[i];
      if (a.cutoffHz != b.cutoffHz ||
          a.gainDb != b.gainDb ||
          a.q != b.q ||
          a.isShelf != b.isShelf) {
        return true;
      }
    }
    return false;
  }
}
