part of 'automation_shape_panel.dart';

class _ShapeChip extends StatelessWidget {
  const _ShapeChip({
    required this.shape,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final AutomationCurveShape shape;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? accent : Colors.white.withValues(alpha: 0.72);

    return Tooltip(
      message: shape.accessibilityLabel,
      child: Semantics(
        button: true,
        selected: selected,
        label: shape.accessibilityLabel,
        child: Material(
          color: selected
              ? accent.withValues(alpha: 0.22)
              : const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      selected ? accent : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: AutomationShapeIcon(shape: shape, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
