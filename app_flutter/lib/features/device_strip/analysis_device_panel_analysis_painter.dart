part of 'analysis_device_panel.dart';

class _AnalysisPainter extends CustomPainter {
  const _AnalysisPainter(
      {required this.type,
      required this.reading,
      required this.accent,
      required this.integrated});

  static const _axisLeft = 28.0;
  static const _axisBottom = 16.0;
  static const _axisTop = 4.0;

  final String type;
  final DeviceMeterReading? reading;
  final Color accent;
  final double integrated;

  Rect _plotRect(Size size) => Rect.fromLTWH(
        _axisLeft,
        _axisTop,
        math.max(1, size.width - _axisLeft - 2),
        math.max(1, size.height - _axisBottom - _axisTop),
      );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF14141E));
    final plot = _plotRect(size);
    switch (type) {
      case 'oscilloscope':
        _drawScopeGrid(canvas, plot);
        _drawScopeAxes(canvas, plot);
        _scope(canvas, plot);
      case 'spectrum_analyzer':
        _drawSpectrumGrid(canvas, plot);
        _drawSpectrumAxes(canvas, plot);
        _spectrum(canvas, plot);
      case 'loudness_meter':
        _loudness(canvas, size);
      case 'stereo_imager':
        _drawStereoGrid(canvas, size);
        _stereo(canvas, size);
    }
  }

  void _drawScopeGrid(Canvas c, Rect plot) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = .5;
    for (var i = 1; i < 5; i++) {
      final x = plot.left + plot.width * i / 5;
      c.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
    }
    for (final level in [-1.0, -0.5, 0.0, 0.5, 1.0]) {
      final y = plot.top + plot.height * (0.5 - level * 0.42);
      c.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
  }

  void _drawScopeAxes(Canvas c, Rect plot) {
    final tick = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..strokeWidth = 1;
    final centerY = plot.top + plot.height * 0.5;
    c.drawLine(Offset(plot.left, centerY), Offset(plot.right, centerY), tick);
    for (final level in [-1.0, -0.5, 0.0, 0.5, 1.0]) {
      final y = plot.top + plot.height * (0.5 - level * 0.42);
      c.drawLine(Offset(plot.left - 5, y), Offset(plot.left, y), tick);
      final label = level == 0
          ? '0'
          : level > 0
              ? '+${level.toStringAsFixed(1)}'
              : level.toStringAsFixed(1);
      _text(c, label, Offset(2, y - 5), 8, Colors.white38);
    }
    for (final frac in [0.0, 0.5, 1.0]) {
      final x = plot.left + plot.width * frac;
      c.drawLine(Offset(x, plot.bottom), Offset(x, plot.bottom + 4), tick);
    }
    _text(c, 't', Offset(plot.right - 6, plot.bottom + 2), 8, Colors.white38);
  }

  void _drawSpectrumGrid(Canvas c, Rect plot) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = .5;
    for (final hz in [20.0, 100.0, 1000.0, 10000.0, 20000.0]) {
      final x = _logFreqX(hz, plot);
      c.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
    }
    for (final db in [0.0, -20.0, -40.0, -60.0]) {
      final y = _dbY(db, plot);
      c.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
  }

  void _drawSpectrumAxes(Canvas c, Rect plot) {
    final tick = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..strokeWidth = 1;
    c.drawLine(
        Offset(plot.left, plot.bottom), Offset(plot.right, plot.bottom), tick);
    c.drawLine(
        Offset(plot.left, plot.top), Offset(plot.left, plot.bottom), tick);
    for (final db in [0.0, -20.0, -40.0, -60.0, -80.0]) {
      final y = _dbY(db, plot);
      c.drawLine(Offset(plot.left - 5, y), Offset(plot.left, y), tick);
      if (db == 0 || db == -40 || db == -80) {
        _text(c, '${db.toInt()}', Offset(2, y - 5), 8, Colors.white38);
      }
    }
    for (final entry in [
      (20.0, '20'),
      (100.0, '100'),
      (1000.0, '1k'),
      (10000.0, '10k'),
      (20000.0, '20k'),
    ]) {
      final x = _logFreqX(entry.$1, plot);
      c.drawLine(Offset(x, plot.bottom), Offset(x, plot.bottom + 4), tick);
      _text(c, entry.$2, Offset(x - 8, plot.bottom + 2), 8, Colors.white38);
    }
    _text(c, 'dB', Offset(2, plot.top - 1), 8, Colors.white38);
  }

  void _drawStereoGrid(Canvas c, Size s) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .05)
      ..strokeWidth = .5;
    for (var i = 1; i < 5; i++) {
      c.drawLine(
          Offset(s.width * i / 5, 0), Offset(s.width * i / 5, s.height), grid);
      c.drawLine(
          Offset(0, s.height * i / 5), Offset(s.width, s.height * i / 5), grid);
    }
  }

  double _logFreqX(double hz, Rect plot) {
    const minHz = 20.0;
    const maxHz = 20000.0;
    final t =
        (math.log(hz) - math.log(minHz)) / (math.log(maxHz) - math.log(minHz));
    return plot.left + plot.width * t.clamp(0.0, 1.0);
  }

  double _dbY(double db, Rect plot) {
    final norm = (db + 80.0) / 80.0;
    return plot.bottom - plot.height * norm.clamp(0.0, 1.0);
  }

  void _scope(Canvas c, Rect plot) {
    final values = reading?.waveform ?? const [];
    if (values.length < 2) return;
    final p = Path();
    for (var i = 0; i < values.length; i++) {
      final o = Offset(plot.left + plot.width * i / (values.length - 1),
          plot.top + plot.height * (0.5 - values[i] * 0.42));
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    c.drawPath(
        p,
        Paint()
          ..color = accent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
  }

  void _spectrum(Canvas c, Rect plot) {
    final values = reading?.spectrum ?? const [];
    if (values.length < 2) return;
    final p = Path()..moveTo(plot.left, plot.bottom);
    for (var i = 0; i < values.length; i++) {
      p.lineTo(plot.left + plot.width * i / (values.length - 1),
          _dbY(values[i] * 80.0 - 80.0, plot));
    }
    p.lineTo(plot.right, plot.bottom);
    p.close();
    c.drawPath(p, Paint()..color = accent.withValues(alpha: .18));
    c.drawPath(
        p,
        Paint()
          ..color = accent
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);
  }

  void _loudness(Canvas c, Size s) {
    final m = reading?.loudnessLufs ?? -70;
    final peak = reading?.inputLevel ?? 0;
    _text(c, '${m.toStringAsFixed(1)}', Offset(18, 18), 30, Colors.white);
    _text(c, 'M  LUFS', Offset(20, 52), 10, Colors.white38);
    _text(c, integrated <= -69 ? '—' : integrated.toStringAsFixed(1),
        Offset(s.width * .52, 20), 22, accent);
    _text(c, 'INTEGRATED', Offset(s.width * .52, 50), 9, Colors.white38);
    final w = (s.width - 36) * ((m + 60) / 60).clamp(0, 1);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(18, s.height - 30, w, 8), const Radius.circular(4)),
        Paint()..color = accent);
    _text(
        c,
        'TP ${(20 * math.log(math.max(peak, 1e-5)) / math.ln10).toStringAsFixed(1)} dB',
        Offset(18, s.height - 18),
        9,
        Colors.white38);
  }

  void _stereo(Canvas c, Size s) {
    final v = reading?.waveform ?? const [];
    final center = Offset(s.width / 2, s.height / 2);
    c.drawCircle(
        center,
        math.min(s.width, s.height) * .37,
        Paint()
          ..color = Colors.white10
          ..style = PaintingStyle.stroke);
    for (var i = 0; i + 1 < v.length; i += 2) {
      final x = center.dx + (v[i] - v[i + 1]) * s.width * .2;
      final y = center.dy - (v[i] + v[i + 1]) * s.height * .2;
      c.drawCircle(
          Offset(x, y), 1.5, Paint()..color = accent.withValues(alpha: .75));
    }
    final corr = ((reading?.correlation ?? 0) + 1) / 2;
    c.drawRect(Rect.fromLTWH(16, s.height - 16, (s.width - 32) * corr, 4),
        Paint()..color = accent);
  }

  void _text(Canvas c, String t, Offset o, double z, Color color) {
    final p = TextPainter(
        text: TextSpan(
            text: t,
            style: TextStyle(
                fontSize: z, color: color, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr)
      ..layout();
    p.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant _AnalysisPainter old) =>
      old.reading != reading ||
      old.integrated != integrated ||
      old.type != type;
}
