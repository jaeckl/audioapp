part of 'sample_editor_screen.dart';

class _SliceTabButton extends StatelessWidget {
  const _SliceTabButton({
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
            ? ArrangementLoopRegionTheme.color.withValues(alpha: .16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        size: 14,
                        color: active
                            ? ArrangementLoopRegionTheme.color
                            : Colors.white54),
                    const SizedBox(width: 5),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .25,
                            color: active
                                ? ArrangementLoopRegionTheme.color
                                : Colors.white60)),
                  ],
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: active
                          ? ArrangementLoopRegionTheme.color
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
