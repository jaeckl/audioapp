part of 'time_fx_panels.dart';

class _ChorusModulationLinePainter extends CustomPainter {
  const _ChorusModulationLinePainter({
    required this.value,
    required this.amount,
    required this.inAssignment,
  });

  final double value;
  final double amount;
  final bool inAssignment;

  @override
  void paint(Canvas canvas, Size size) {
    final start = (value.clamp(0.0, 3.0) / 3.0) * size.width;
    final end =
        (start + amount.clamp(-1.0, 1.0) * size.width).clamp(0.0, size.width);
    canvas.drawLine(
      Offset(start, size.height - 2.5),
      Offset(end, size.height - 2.5),
      Paint()
        ..color = Colors.white.withValues(alpha: inAssignment ? .9 : .6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChorusModulationLinePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.amount != amount ||
      oldDelegate.inAssignment != inAssignment;
}
