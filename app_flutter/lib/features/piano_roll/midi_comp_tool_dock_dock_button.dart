part of 'midi_comp_tool_dock.dart';

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
    required this.active,
    required this.onTap,
    this.label,
    this.compact = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
  final String? label;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? PianoRollTheme.dockActive : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: compact ? 44 : 56,
            height: PianoRollMetrics.toolDockHeight,
            child: label == null
                ? Icon(
                    active ? activeIcon : icon,
                    size: 22,
                    color: active
                        ? PianoRollTheme.dockIconActive
                        : PianoRollTheme.dockIcon,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? activeIcon : icon,
                        size: 18,
                        color: active
                            ? PianoRollTheme.dockIconActive
                            : PianoRollTheme.dockIcon,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label!,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: active
                              ? PianoRollTheme.dockIconActive
                              : PianoRollTheme.dockIcon,
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
