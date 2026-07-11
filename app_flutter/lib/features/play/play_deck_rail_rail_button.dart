part of 'play_deck_rail.dart';

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? PlayDeckTheme.railActive
        : enabled
            ? PlayDeckTheme.railInactive
            : PlayDeckTheme.railLabel;
    return Material(
      color: active ? const Color(0xFF2A2A30) : Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
