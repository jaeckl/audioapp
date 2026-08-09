part of 'play_deck_rail.dart';

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;
  final bool compact;

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
          width: compact ? 48 : null,
          height: compact ? 48 : 56,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: compact ? 18 : 20, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
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
