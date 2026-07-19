part of 'mixer_view.dart';

/// Flat inset well (no gradients) for gain / pan rails.
void paintEngravedWell(Canvas canvas, RRect well) {
  canvas.drawRRect(well, Paint()..color = MixerTheme.wellFill);
  canvas.drawRRect(
    well,
    Paint()
      ..color = MixerTheme.wellRim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
}

void paintFaderCap(
  Canvas canvas, {
  required RRect cap,
  required Color accent,
  required bool horizontalTick,
}) {
  canvas.drawRRect(
    cap.shift(const Offset(0, 1)),
    Paint()..color = Colors.black.withValues(alpha: 0.4),
  );
  canvas.drawRRect(cap, Paint()..color = MixerTheme.capFill);
  canvas.drawRRect(
    cap,
    Paint()
      ..color = MixerTheme.capEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );

  final c = cap.center;
  final tick = Paint()
    ..color = accent
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  if (horizontalTick) {
    canvas.drawLine(
      Offset(c.dx - cap.outerRect.width * 0.28, c.dy),
      Offset(c.dx + cap.outerRect.width * 0.28, c.dy),
      tick,
    );
  } else {
    canvas.drawLine(
      Offset(c.dx, c.dy - cap.outerRect.height * 0.28),
      Offset(c.dx, c.dy + cap.outerRect.height * 0.28),
      tick,
    );
  }
}
