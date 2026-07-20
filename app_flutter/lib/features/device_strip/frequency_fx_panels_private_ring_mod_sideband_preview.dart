part of 'frequency_fx_panels.dart';

/// Param-bound ring-mod sideband sketch: dry center + ±carrier lobes.
class _RingModSidebandPreview extends StatelessWidget {
  const _RingModSidebandPreview({
    required this.carrierHz,
    required this.mix,
    required this.tone,
    required this.feedback,
    required this.accent,
  });

  final double carrierHz;
  final double mix;
  final double tone;
  final double feedback;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingModSidebandPainter(
        carrierHz: carrierHz,
        mix: mix,
        tone: tone,
        feedback: feedback,
        accent: accent,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RingModSidebandPainter extends CustomPainter {
  _RingModSidebandPainter({
    required this.carrierHz,
    required this.mix,
    required this.tone,
    required this.feedback,
    required this.accent,
  });

  final double carrierHz;
  final double mix;
  final double tone;
  final double feedback;
  final Color accent;

  static const _maxAbsHz = 2050.0;

  @override
  void paint(Canvas canvas, Size size) {
    final padL = 6.0;
    final padR = 6.0;
    final padT = 10.0;
    final padB = 14.0;
    final plot = Rect.fromLTWH(
      padL,
      padT,
      math.max(0.0, size.width - padL - padR),
      math.max(0.0, size.height - padT - padB),
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final midX = plot.center.dx;
    final baseY = plot.bottom;

    // Zero / dry axis.
    canvas.drawLine(
      Offset(plot.left, baseY),
      Offset(plot.right, baseY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(midX, plot.top),
      Offset(midX, plot.bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 1,
    );

    double xForHz(double hz) {
      final t = ((hz + _maxAbsHz) / (2 * _maxAbsHz)).clamp(0.0, 1.0);
      return plot.left + t * plot.width;
    }

    final wetAlpha = (0.25 + 0.75 * mix.clamp(0.0, 1.0));
    final lobeH = plot.height * (0.35 + 0.45 * mix.clamp(0.0, 1.0));
    final toneScale = 0.45 + 0.55 * tone.clamp(0.0, 1.0);
    final fbBloom = feedback.clamp(0.0, 1.0) * 0.35;

    void drawLobe(double hz, Color color) {
      final x = xForHz(hz);
      final h = lobeH * toneScale;
      final path = Path()
        ..moveTo(x - 10 - fbBloom * 8, baseY)
        ..quadraticBezierTo(x, baseY - h, x + 10 + fbBloom * 8, baseY);
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.55 * wetAlpha)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, baseY - h),
        3.5 + fbBloom * 2,
        Paint()..color = color.withValues(alpha: wetAlpha),
      );
    }

    // Dry residual (shrinks with mix).
    final dryH = plot.height * 0.55 * (1.0 - mix.clamp(0.0, 1.0) * 0.85);
    canvas.drawLine(
      Offset(midX, baseY),
      Offset(midX, baseY - dryH),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(midX, baseY - dryH),
      3.5,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );

    final c = carrierHz.clamp(-_maxAbsHz, _maxAbsHz);
    drawLobe(-c.abs(), accent);
    drawLobe(c.abs(), accent);

    // Labels.
    final style = TextStyle(
      color: Colors.white.withValues(alpha: 0.5),
      fontSize: 8,
      fontWeight: FontWeight.w600,
    );
    void label(String text, double x) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset((x - tp.width / 2).clamp(0.0, size.width - tp.width), plot.bottom + 2),
      );
    }

    label('−2k', xForHz(-2000));
    label('0', midX);
    label('+2k', xForHz(2000));

    final readout = TextPainter(
      text: TextSpan(
        text: _fmtCarrier(carrierHz),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    readout.paint(canvas, Offset(plot.left, 2));
  }

  static String _fmtCarrier(double hz) {
    final a = hz.abs();
    final sign = hz >= 0 ? '+' : '−';
    if (a >= 1000) return 'carrier $sign${(a / 1000).toStringAsFixed(2)} kHz';
    return 'carrier $sign${a.toStringAsFixed(0)} Hz';
  }

  @override
  bool shouldRepaint(covariant _RingModSidebandPainter old) =>
      old.carrierHz != carrierHz ||
      old.mix != mix ||
      old.tone != tone ||
      old.feedback != feedback ||
      old.accent != accent;
}
