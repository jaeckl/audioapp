part of 'drum_model_tab_bar.dart';

class _TabCell extends StatelessWidget {
  const _TabCell({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.accent,
    required this.theme,
    required this.showLeftDivider,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final Color accent;
  final ThemeData theme;
  final bool showLeftDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? accent
        : enabled
            ? Colors.white60
            : Colors.white.withValues(alpha: 0.28);

    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: showLeftDivider
                  ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
                  : BorderSide.none,
              bottom: selected
                  ? BorderSide(color: accent, width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 9,
                letterSpacing: 0.35,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
