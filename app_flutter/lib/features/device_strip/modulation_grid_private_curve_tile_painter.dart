part of 'modulation_grid.dart';

class _CurveTilePainter extends CustomPainter {
  _CurveTilePainter({
    required this.positions,
    required this.values,
    required this.accent,
  });

  final List<double> positions;
  final List<double> values;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.75)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final count = positions.length;
    if (count < 2) return;
    final path = Path();
    for (var i = 0; i < count; i++) {
      final x = positions[i].clamp(0.0, 1.0) * size.width;
      final y = size.height * (0.5 - values[i].clamp(-1.0, 1.0) * 0.5);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CurveTilePainter old) =>
      old.positions != positions || old.values != values;
}
