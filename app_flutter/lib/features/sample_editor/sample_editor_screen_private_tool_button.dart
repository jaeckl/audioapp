part of 'sample_editor_screen.dart';

class _ToolButton extends StatelessWidget {
  const _ToolButton(
      {required this.icon,
      required this.tooltip,
      required this.onTap,
      this.label,
      this.compact = false,
      this.active = false});
  final IconData icon;
  final String tooltip;
  final String? label;
  final VoidCallback onTap;
  final bool active, compact;
  @override
  Widget build(BuildContext context) => Tooltip(
      message: tooltip,
      child: Material(
        color: active ? AutomationEditorTheme.dockActive : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
              width: compact ? 42 : 57,
              height: 46,
              child: label == null
                  ? Icon(icon,
                      size: 21,
                      color: active
                          ? AutomationEditorTheme.dockIconActive
                          : AutomationEditorTheme.dockIcon)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Icon(icon,
                              size: 18,
                              color: active
                                  ? AutomationEditorTheme.dockIconActive
                                  : AutomationEditorTheme.dockIcon),
                          const SizedBox(height: 2),
                          Text(label!,
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? AutomationEditorTheme.dockIconActive
                                      : AutomationEditorTheme.dockIcon)),
                        ])),
        ),
      ));
}
