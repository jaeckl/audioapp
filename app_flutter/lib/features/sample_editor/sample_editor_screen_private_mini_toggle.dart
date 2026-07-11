part of 'sample_editor_screen.dart';

class _MiniToggle extends StatelessWidget {
  const _MiniToggle(
      {required this.label,
      required this.onTap,
      this.active = false,
      this.icon});
  final String label;
  final VoidCallback onTap;
  final bool active;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onTap,
          child: Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: active
                  ? AutomationEditorTheme.accent.withValues(alpha: .22)
                  : Colors.white.withValues(alpha: .035),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: Colors.white60),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 9,
                        color: active
                            ? AutomationEditorTheme.accent
                            : Colors.white70)),
              ),
              if (icon == null)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        active ? AutomationEditorTheme.accent : Colors.white24,
                  ),
                ),
            ]),
          ),
        ),
      );
}
