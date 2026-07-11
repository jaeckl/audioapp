part of 'mood_fx_panels.dart';

class _StutterMiniToggle extends StatelessWidget {
  const _StutterMiniToggle({
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              label,
              style: TextStyle(
                color: active ? accent : Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
