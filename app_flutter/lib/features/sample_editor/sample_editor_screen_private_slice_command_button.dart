part of 'sample_editor_screen.dart';

class _SliceCommandButton extends StatelessWidget {
  const _SliceCommandButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final accent = ArrangementLoopRegionTheme.color;
    return Material(
      color: !enabled
          ? Colors.white.withValues(alpha: .025)
          : primary
              ? accent.withValues(alpha: .20)
              : Colors.white.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: !enabled
                      ? Colors.white24
                      : primary
                          ? accent
                          : Colors.white60),
              const SizedBox(width: 5),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: !enabled
                            ? Colors.white24
                            : primary
                                ? accent
                                : Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
