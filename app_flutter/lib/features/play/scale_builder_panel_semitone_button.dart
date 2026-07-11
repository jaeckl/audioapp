part of 'scale_builder_panel.dart';

class _SemitoneButton extends StatelessWidget {
  const _SemitoneButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isRoot = false,
    this.small = false,
  });

  final String label;
  final bool selected;
  final bool isRoot;
  final bool small;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isRoot
          ? PlayDeckTheme.optionActive
          : selected
              ? const Color(0xFF3A3A44)
              : PlayDeckTheme.optionIdle,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: small ? 1.0 : 1.6,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: small ? 9 : 11,
                color: isRoot
                    ? Colors.black
                    : selected
                        ? PlayDeckTheme.optionLabel
                        : PlayDeckTheme.railLabel,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
