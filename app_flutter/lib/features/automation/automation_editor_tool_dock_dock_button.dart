part of 'automation_editor_tool_dock.dart';

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AutomationEditorTheme.dockActive : Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 40,
          height: AutomationEditorMetrics.toolDockHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? activeIcon : icon,
                size: 22,
                color: enabled
                    ? (active
                        ? AutomationEditorTheme.dockIconActive
                        : AutomationEditorTheme.dockIcon)
                    : AutomationEditorTheme.labelMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
