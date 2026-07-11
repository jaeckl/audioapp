part of 'piano_roll_tool_dock.dart';

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.enabled = true,
    this.showLabel = false,
    this.onLongPress,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool enabled;
  final bool showLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? PianoRollTheme.dockActive : Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        child: SizedBox(
          width: showLabel ? 72 : 52,
          height: PianoRollMetrics.toolDockHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? activeIcon : icon,
                size: 22,
                color: enabled
                    ? (active
                        ? PianoRollTheme.dockIconActive
                        : PianoRollTheme.dockIcon)
                    : PianoRollTheme.labelMuted,
              ),
              if (showLabel) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? PianoRollTheme.dockIcon
                        : PianoRollTheme.labelMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
