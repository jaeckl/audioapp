part of 'sample_editor_screen.dart';

class _SliceChoiceChip extends StatelessWidget {
  const _SliceChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active
            ? ArrangementLoopRegionTheme.color.withValues(alpha: .18)
            : Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Container(
            height: 34,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: active
                    ? ArrangementLoopRegionTheme.color.withValues(alpha: .55)
                    : Colors.white.withValues(alpha: .08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                        color: active
                            ? ArrangementLoopRegionTheme.color
                            : Colors.white54)),
              ],
            ),
          ),
        ),
      );
}
