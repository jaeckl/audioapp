part of 'sample_editor_screen.dart';

class _SliceIconButton extends StatelessWidget {
  const _SliceIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: onTap == null ? .025 : .05),
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            borderRadius: BorderRadius.circular(7),
            onTap: onTap,
            child: SizedBox(
              width: 34,
              height: 36,
              child: Icon(icon,
                  size: 18,
                  color: onTap == null ? Colors.white24 : Colors.white70),
            ),
          ),
        ),
      );
}
