part of 'device_tool_rail.dart';

class _StatusDot extends StatelessWidget {
  const _StatusDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(width: 7, height: 7),
      ),
    );
  }
}
