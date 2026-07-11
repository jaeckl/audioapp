part of 'modulation_strip.dart';

class _MiniSlider extends StatelessWidget {
  const _MiniSlider({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final double value;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final delta = details.delta.dx / constraints.maxWidth;
            onChanged((value + delta).clamp(0.0, 1.0));
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D14),
              borderRadius: BorderRadius.circular(3),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Container(
                  width: constraints.maxWidth * value,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A54B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
