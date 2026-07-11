part of 'mood_fx_panels.dart';

class _StutterModLine extends StatelessWidget {
  const _StutterModLine({
    required this.amount,
    required this.color,
  });

  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final normalized = amount.abs().clamp(0.0, 1.0);
    return Align(
      alignment: amount >= 0 ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: normalized,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
