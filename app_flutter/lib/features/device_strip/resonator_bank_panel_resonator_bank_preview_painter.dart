part of 'resonator_bank_panel.dart';

class ResonatorBankPreviewPainter extends CustomPainter {
  const ResonatorBankPreviewPainter({
    required this.root,
    required this.spread,
    required this.decay,
    required this.damping,
    required this.color,
    required this.width,
    required this.accent,
  });

  final double root;
  final double spread;
  final double decay;
  final double damping;
  final double color;
  final double width;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Colors.white.withValues(alpha: 0.055);
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final rootMidi = 24 + root.clamp(0.0, 1.0) * 72;
    final rootHz = 440 * math.pow(2, (rootMidi - 69) / 12);
    final exponent = 0.5 + spread.clamp(0.0, 1.0);
    for (var band = 0; band < 6; band++) {
      final ratio = math.pow(band + 1, exponent).toDouble();
      final hz = (rootHz * ratio).clamp(20.0, 20000.0);
      final x = ((math.log(hz / 20) / math.log(1000)) * size.width)
          .clamp(4.0, size.width - 4);
      final octave = math.log(math.max(ratio, 1)) / math.ln2;
      final colorGain =
          math.pow(10, ((color - 0.5) * 24 * octave) / 20).toDouble();
      final damp = math.exp(-damping * octave * 1.4);
      final peak = (0.32 + decay * 0.55) * damp * colorGain.clamp(0.28, 2.2);
      final height = (size.height * peak).clamp(8.0, size.height * 0.88);
      final stereo = (band.isEven ? -1 : 1) * width;
      final bandColor = Color.lerp(
          accent,
          stereo < 0 ? Colors.cyanAccent : Colors.pinkAccent,
          stereo.abs().clamp(0.0, 1.0) * 0.28)!;
      final glow = Paint()
        ..color = bandColor.withValues(alpha: 0.14)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      final line = Paint()
        ..color = bandColor.withValues(alpha: 0.88)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, size.height - 7),
          Offset(x, size.height - 7 - height), glow);
      canvas.drawLine(Offset(x, size.height - 7),
          Offset(x, size.height - 7 - height), line);
      canvas.drawCircle(
          Offset(x, size.height - 7 - height), 2.8, Paint()..color = bandColor);
    }
  }

  @override
  bool shouldRepaint(covariant ResonatorBankPreviewPainter oldDelegate) =>
      root != oldDelegate.root ||
      spread != oldDelegate.spread ||
      decay != oldDelegate.decay ||
      damping != oldDelegate.damping ||
      color != oldDelegate.color ||
      width != oldDelegate.width;
}
