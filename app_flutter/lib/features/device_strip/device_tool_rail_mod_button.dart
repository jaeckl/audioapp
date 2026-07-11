part of 'device_tool_rail.dart';

class _ModButton extends StatelessWidget {
  const _ModButton({
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Modulation',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
      onPressed: onPressed,
      icon: Icon(
        Icons.cable,
        size: 18,
        color: active ? const Color(0xFFE8A54B) : Colors.white54,
      ),
    );
  }
}
