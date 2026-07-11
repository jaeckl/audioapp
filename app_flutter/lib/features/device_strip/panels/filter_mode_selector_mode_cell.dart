part of 'filter_mode_selector.dart';

class _ModeCell extends StatelessWidget {
  const _ModeCell({
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.18) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }
}
