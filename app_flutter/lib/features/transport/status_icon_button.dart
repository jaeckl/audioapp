part of 'transport_bar.dart';

class _StatusIconButton extends StatelessWidget {
  const _StatusIconButton({
    required this.icon,
    required this.tooltip,
    this.accent,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? TransportBarTheme.textSecondary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: accent != null
            ? accent!.withValues(alpha: 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Icon(icon,
                size: TransportBarTheme.statusIconSize, color: color),
          ),
        ),
      ),
    );
  }
}
