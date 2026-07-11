part of 'mod_strip.dart';

class _Readout extends StatelessWidget {
  const _Readout({
    required this.value,
    required this.color,
    this.center = false,
  });

  final double value;
  final Color color;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 8,
      child: CustomPaint(painter: _ReadoutPainter(value, color, center)),
    );
  }
}
