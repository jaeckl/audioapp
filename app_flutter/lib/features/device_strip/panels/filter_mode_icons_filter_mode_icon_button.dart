part of 'filter_mode_icons.dart';

class FilterModeIconButton extends StatelessWidget {
  const FilterModeIconButton({
    super.key,
    required this.mode,
    required this.selected,
    required this.onTap,
    this.accentColor = const Color(0xFF5BC0EB),
    this.size = 34,
  });

  final FilterCurveMode mode;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? accentColor : Colors.white.withValues(alpha: 0.38);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        splashColor: accentColor.withValues(alpha: 0.12),
        highlightColor: accentColor.withValues(alpha: 0.06),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: FilterCurveIconPainter(
              mode: mode,
              color: fg,
              strokeWidth: (size * 0.05).clamp(1.4, 2.2),
            ),
          ),
        ),
      ),
    );
  }
}
