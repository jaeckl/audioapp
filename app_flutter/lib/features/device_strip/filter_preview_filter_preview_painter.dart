part of 'filter_preview.dart';

class _FilterPreviewPainter extends CustomPainter {
  _FilterPreviewPainter({
    required this.cutoffHz,
    required this.q,
    required this.mode,
    required this.accent,
  });

  final double cutoffHz;
  final double q;
  final FilterPreviewMode mode;
  final Color accent;

  static const double _minFreq = 20.0;
  static const double _maxFreq = 20000.0;
  static const double _minDb = -24.0;
  static const double _maxDb = 6.0;

  static const double _padL = 10.0;
  static const double _padR = 10.0;
  /// Live readout only at top.
  static const double _padT = 14.0;
  /// Freq scale band at bottom.
  static const double _padB = 16.0;

  /// Inset curve mapping so stroke + handle never kiss edges.
  static const double _curveInset = 8.0;
  static const double _handleRadius = 3.6;
  static const double _strokeWidth = 1.8;

  static const _freqLabels = <(double, String)>[
    (20.0, '20'),
    (100.0, '100'),
    (1000.0, '1k'),
    (10000.0, '10k'),
    (20000.0, '20k'),
  ];

  static const _majorFreqs = <double>[100.0, 1000.0, 10000.0];

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(
      _padL,
      _padT,
      math.max(0.0, size.width - _padL - _padR),
      math.max(0.0, size.height - _padT - _padB),
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final curve = plot.deflate(_curveInset);
    if (curve.width <= 0 || curve.height <= 0) return;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = 1.0;

    for (final f in _majorFreqs) {
      final x = _freqToX(f, curve.width) + curve.left;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gridPaint);
    }

    final zeroY = _dbToY(0, curve.height) + curve.top;
    canvas.drawLine(
      Offset(plot.left, zeroY),
      Offset(plot.right, zeroY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 1.0,
    );

    final readout = TextPainter(
      text: TextSpan(
        text: '${_formatHz(cutoffHz)} · Q ${_formatQ(q)}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: curve.width * 0.72);
    readout.paint(canvas, Offset(curve.left, 3));

    final zeroLabel = TextPainter(
      text: TextSpan(
        text: '0',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.30),
          fontSize: 7,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    zeroLabel.paint(
      canvas,
      Offset(curve.right - zeroLabel.width, zeroY - zeroLabel.height - 1),
    );

    final stepCount = math.max(80, curve.width.toInt());
    final points = <Offset>[];
    for (var i = 0; i <= stepCount; i++) {
      final t = i / stepCount;
      final localX = t * curve.width;
      final f = _xToFreq(localX, curve.width);
      final db = BiquadResponse.compute(
        cutoffHz: cutoffHz,
        q: q,
        mode: mode.index,
        frequencyHz: f,
      );
      points.add(Offset(
        localX + curve.left,
        _dbToY(db, curve.height) + curve.top,
      ));
    }

    final strokePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      strokePath.lineTo(points[i].dx, points[i].dy);
    }

    final fillClip = curve.inflate(_strokeWidth);
    canvas.save();
    canvas.clipRect(fillClip);
    final fillPath = Path.from(strokePath)
      ..lineTo(points.last.dx, fillClip.bottom)
      ..lineTo(points.first.dx, fillClip.bottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.14),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(curve),
    );
    canvas.restore();

    canvas.drawPath(
      strokePath,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    final clampedCutoff = cutoffHz.clamp(_minFreq, _maxFreq);
    final cutoffX = _freqToX(clampedCutoff, curve.width) + curve.left;
    final cutoffDb = BiquadResponse.compute(
      cutoffHz: cutoffHz,
      q: q,
      mode: mode.index,
      frequencyHz: clampedCutoff,
    );
    final cutoffY = _dbToY(cutoffDb, curve.height) + curve.top;

    canvas.drawLine(
      Offset(cutoffX, curve.top),
      Offset(cutoffX, curve.bottom),
      Paint()
        ..color = accent.withValues(alpha: 0.32)
        ..strokeWidth = 1.0,
    );
    canvas.drawCircle(
      Offset(cutoffX, cutoffY),
      _handleRadius,
      Paint()..color = const Color(0xFF07070A),
    );
    canvas.drawCircle(
      Offset(cutoffX, cutoffY),
      2.5,
      Paint()..color = accent,
    );

    // Freq scale along the bottom of the plot.
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.48),
      fontSize: 8,
      fontWeight: FontWeight.w600,
      height: 1,
    );
    for (final entry in _freqLabels) {
      final x = _freqToX(entry.$1, curve.width) + curve.left;
      canvas.drawLine(
        Offset(x, plot.bottom),
        Offset(x, plot.bottom + 4),
        tickPaint,
      );
      final tp = TextPainter(
        text: TextSpan(text: entry.$2, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelX = (x - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(labelX, plot.bottom + 5));
    }
  }

  static String _formatHz(double hz) {
    if (hz >= 1000) {
      final k = hz / 1000;
      return k >= 10 ? '${k.round()} kHz' : '${k.toStringAsFixed(2)} kHz';
    }
    return '${hz.round()} Hz';
  }

  static String _formatQ(double q) => q.toStringAsFixed(2);

  static double _freqToX(double f, double w) {
    final clamped = f.clamp(_minFreq, _maxFreq);
    final norm =
        (math.log(clamped / _minFreq)) / math.log(_maxFreq / _minFreq);
    return norm * w;
  }

  static double _xToFreq(double x, double w) {
    final norm = (x / w).clamp(0.0, 1.0);
    return _minFreq * math.pow(_maxFreq / _minFreq, norm);
  }

  static double _dbToY(double db, double h) {
    final clamped = db.clamp(_minDb, _maxDb);
    return h * (1.0 - (clamped - _minDb) / (_maxDb - _minDb));
  }

  @override
  bool shouldRepaint(covariant _FilterPreviewPainter old) =>
      old.cutoffHz != cutoffHz ||
      old.q != q ||
      old.mode != mode ||
      old.accent != accent;
}
