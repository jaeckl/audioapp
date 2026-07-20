part of 'filter_mode_selector.dart';

class _ModeCell extends StatelessWidget {
  const _ModeCell({
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.child,
    this.flush = false,
  });

  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final Widget child;
  final bool flush;

  @override
  Widget build(BuildContext context) {
    if (flush) {
      // Bitwig-style screen chrome: quiet accent wash (≤12%) + an accent
      // underline beneath the glyph. Opaque hit test so taps land reliably
      // even on the transparent (unselected) surface.
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: selected
                  ? accent.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            Center(child: child),
            if (selected)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(height: 2, color: accent),
              ),
          ],
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.22)
              : const Color(0xFF222229),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.55)
                : const Color(0xFF3A3A48),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
