part of 'mood_fx_panels.dart';

class _StutterShapePanel extends StatelessWidget {
  const _StutterShapePanel({
    required this.accent,
    required this.top,
    required this.bottom,
  });

  final Color accent;
  final List<Widget> top;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF101018),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: top,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: bottom,
            ),
          ],
        ),
      ),
    );
  }
}
