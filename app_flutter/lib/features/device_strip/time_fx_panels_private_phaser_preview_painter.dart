part of 'time_fx_panels.dart';

class _PhaserPreviewPainter extends CustomPainter {
  const _PhaserPreviewPainter({required this.device, required this.view});

  final PhaserDeviceSnapshot device;
  final PhaserViewTab view;

  void _text(Canvas canvas, String value, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  double _wave(double phase) {
    final p = phase - phase.floorToDouble();
    return switch (device.phaserWaveform.round().clamp(0, 3)) {
      1 => 1 - 4 * (p - .5).abs(),
      2 => 2 * p - 1,
      3 => math.sin((phase.floor() * 91.7) + 1.2) >= 0 ? .75 : -.75,
      _ => math.sin(phase * math.pi * 2),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(7, size.height * i / 4),
        Offset(size.width - 7, size.height * i / 4),
        grid,
      );
    }
    for (var i = 1; i < 5; i++) {
      canvas.drawLine(
        Offset(size.width * i / 5, 7),
        Offset(size.width * i / 5, size.height - 7),
        grid,
      );
    }

    if (view == PhaserViewTab.motion) {
      _text(
        canvas,
        'L / R MODULATION · ${(device.phaserStereoPhase * 180).round()}° OFFSET',
        const Offset(8, 8),
      );
      Path curve(double offset) {
        final path = Path();
        for (var x = 8.0; x <= size.width - 8; x += 2) {
          final phase = (x - 8) / (size.width - 16) * 2 + offset;
          final y = size.height * .53 - _wave(phase) * size.height * .3;
          if (x == 8) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        return path;
      }

      canvas.drawPath(
        curve(device.phaserPhaseOffset),
        Paint()
          ..color = PhaserFxPanel.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawPath(
        curve(device.phaserPhaseOffset + device.phaserStereoPhase * .5),
        Paint()
          ..color = const Color(0xFF78AEE8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else {
      final stages = device.phaserStages.round().clamp(2, 12);
      _text(
        canvas,
        '$stages STAGES · ${_formatHz(device.phaserCentreFrequencyHz)} · ${(device.phaserDepth * 4).toStringAsFixed(1)} OCT SWEEP',
        const Offset(8, 8),
      );
      final path = Path();
      for (var x = 7.0; x <= size.width - 7; x += 1.5) {
        final phase = (x - 7) / (size.width - 14) * math.pi * stages;
        final envelope = .35 + .65 * math.sin(phase).abs();
        final y = 24 + envelope * (size.height - 34);
        if (x == 7) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = PhaserFxPanel.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PhaserPreviewPainter oldDelegate) => true;
}
