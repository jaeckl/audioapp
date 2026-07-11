part of 'automation_editor_tool_dock.dart';

class _ShapeDockButton extends StatelessWidget {
  const _ShapeDockButton({
    required this.shape,
    required this.active,
    required this.onTap,
  });

  final AutomationCurveShape shape;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AutomationEditorTheme.dockIconActive
        : AutomationEditorTheme.dockIcon;
    return Material(
      color: active ? AutomationEditorTheme.dockActive : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: AutomationEditorMetrics.toolDockHeight,
          child: Center(
            child: AutomationShapeIcon(shape: shape, color: color),
          ),
        ),
      ),
    );
  }
}
