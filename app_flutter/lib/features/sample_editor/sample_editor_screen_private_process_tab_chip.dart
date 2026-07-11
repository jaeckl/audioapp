part of 'sample_editor_screen.dart';

class _ProcessTabChip extends StatelessWidget {
  const _ProcessTabChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active
            ? AutomationEditorTheme.accent.withValues(alpha: .16)
            : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: active
                    ? AutomationEditorTheme.accent.withValues(alpha: .55)
                    : Colors.white.withValues(alpha: .08),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 12,
                    color:
                        active ? AutomationEditorTheme.accent : Colors.white38),
                const SizedBox(width: 3),
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                        color: active
                            ? AutomationEditorTheme.accent
                            : Colors.white54)),
              ],
            ),
          ),
        ),
      );
}
